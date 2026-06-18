import os
import json
import logging
import io
import base64
from typing import Optional
from fastapi import FastAPI, HTTPException, Body
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv
from supabase import create_client, Client

# Import evaluation algorithms and question matrices
from evaluator import (
    analyze_answer_keywords,
    adjust_difficulty,
    FALLBACK_QUESTIONS,
    BEHAVIORAL_QUESTIONS
)

# Load environment variables
load_dotenv()

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="InterviewerAI Engine", version="1.0.0")

# CORS setup
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize Supabase client
supabase_url = os.getenv("SUPABASE_URL")
supabase_key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

if not supabase_url or not supabase_key:
    logger.warning("SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY not configured in backend-ai.")
    supabase = None
else:
    try:
        supabase: Client = create_client(supabase_url, supabase_key)
        logger.info("Supabase client initialized successfully in backend-ai.")
    except Exception as e:
        logger.error(f"Failed to initialize Supabase client: {e}")
        supabase = None

# Initialize Google Gemini Client if key available
gemini_key = os.getenv("GEMINI_API_KEY")
gemini_client = None
if gemini_key:
    try:
        from google import genai
        gemini_client = genai.Client(api_key=gemini_key)
        logger.info("Gemini API client initialized successfully using google-genai.")
    except Exception as e:
        logger.error(f"Failed to initialize Gemini Client: {e}")
else:
    logger.warning("GEMINI_API_KEY not found in environment. Running in offline/rule-based mode.")

# Pydantic schemas
class EvaluationRequest(BaseModel):
    interview_id: str
    user_answer: str
    step_order: int  # 1 to 6
    current_difficulty: int  # 1 to 5
    domain: str
    experience_tier: str
    resume_context: Optional[str] = None

class ResumeAnalyzeRequest(BaseModel):
    fileContent: Optional[str] = None
    fileBytes: Optional[str] = None
    fileName: str
    targetJob: str

def extract_text_from_pdf(pdf_bytes: bytes) -> str:
    try:
        from pypdf import PdfReader
        pdf_file = io.BytesIO(pdf_bytes)
        reader = PdfReader(pdf_file)
        text = ""
        for page in reader.pages:
            text += page.extract_text() or ""
        return text.strip()
    except Exception as e:
        logger.error(f"pypdf extraction failed: {e}")
        # Fallback ASCII string scraper
        return "".join(chr(b) for b in pdf_bytes if 32 <= b <= 126 or b in (10, 13))[:4000]

def extract_text_from_docx(docx_bytes: bytes) -> str:
    try:
        from docx import Document
        docx_file = io.BytesIO(docx_bytes)
        doc = Document(docx_file)
        text = ""
        for para in doc.paragraphs:
            text += para.text + "\n"
        return text.strip()
    except Exception as e:
        logger.error(f"python-docx extraction failed: {e}")
        # Fallback ASCII string scraper
        return "".join(chr(b) for b in docx_bytes if 32 <= b <= 126 or b in (10, 13))[:4000]

@app.get("/api/health")
def health():
    return {
        "status": "UP",
        "gemini_enabled": gemini_client is not None,
        "supabase_enabled": supabase is not None
    }

@app.post("/api/evaluate")
async def evaluate(req: EvaluationRequest):
    logger.info(f"Evaluating step {req.step_order} for interview {req.interview_id}")
    
    # 1. Fetch current question from Supabase or use fallback
    current_question = ""
    if supabase:
        try:
            res = supabase.table("interview_steps")\
                .select("dynamic_question")\
                .eq("interview_id", req.interview_id)\
                .eq("step_order", req.step_order)\
                .execute()
            if res.data and len(res.data) > 0:
                current_question = res.data[0]["dynamic_question"]
        except Exception as e:
            logger.error(f"Error fetching current step from Supabase: {e}")
            
    if not current_question:
        # Fallback question based on tier/difficulty
        if req.step_order == 6:
            current_question = BEHAVIORAL_QUESTIONS.get(req.domain, "Tell me about a time you solved a hard technical problem.")
        else:
            current_question = FALLBACK_QUESTIONS.get(req.domain, {}).get(req.current_difficulty, "Explain your technical background.")

    # 2. Score the answer (Completeness score C)
    local_eval = analyze_answer_keywords(req.user_answer, current_question, req.domain)
    completeness_score = local_eval["completeness"]
    
    # Let Gemini refine the evaluation if enabled
    ai_feedback = ""
    if gemini_client:
        try:
            prompt = f"""
            You are InterviewerAI, an elite technical interviewer evaluating a candidate's response.
            
            Domain: {req.domain}
            Experience Tier: {req.experience_tier}
            Question: {current_question}
            Candidate Response: {req.user_answer}
            
            Based on the candidate's response:
            1. Analyze what they answered right, what they missed, and any factual errors.
            2. Compute a completeness score C between 0.0 and 1.0 (with 1.0 being perfect).
               Use the rubric:
               C = (Keywords Present + Architecture Mentioned + Trade-offs Explained) / Total Expected Criteria.
            
            Format your output strictly as a JSON object with keys:
            "completeness_score" (float, e.g. 0.85),
            "feedback" (string, 2-3 sentences of specific analytical feedback).
            """
            response = gemini_client.models.generate_content(
                model='gemini-2.5-flash',
                contents=prompt,
                config={'response_mime_type': 'application/json'}
            )
            ai_data = json.loads(response.text)
            completeness_score = float(ai_data.get("completeness_score", completeness_score))
            ai_feedback = ai_data.get("feedback", "")
            logger.info(f"Gemini completeness score: {completeness_score}")
        except Exception as e:
            logger.error(f"Error using Gemini for evaluation: {e}")

    # 3. Update database with user's answer and completeness score
    if supabase:
        try:
            supabase.table("interview_steps")\
                .update({"user_answer": req.user_answer, "completeness_score": completeness_score})\
                .eq("interview_id", req.interview_id)\
                .eq("step_order", req.step_order)\
                .execute()
        except Exception as e:
            logger.error(f"Error updating step answer in Supabase: {e}")

    # 4. Handle State Transitions
    if req.step_order < 6:
        # Calculate next difficulty rank D (1 to 5)
        next_d = adjust_difficulty(req.current_difficulty, completeness_score)
        next_step_order = req.step_order + 1
        next_question = ""

        # Step 6 is always the behavioral question
        if next_step_order == 6:
            next_question = BEHAVIORAL_QUESTIONS.get(req.domain, "Tell me about a time you solved a hard technical problem.")
        else:
            # Generate next technical question
            if gemini_client:
                try:
                    resume_context_str = f"The candidate's resume highlights: {req.resume_context}." if req.resume_context else ""
                    prompt = f"""
                    You are InterviewerAI, an elite technical interviewer.
                    Generate the next clear, concise technical question.
                    
                    Domain: {req.domain}
                    Experience Tier: {req.experience_tier}
                    Target Difficulty: {next_d} (on a scale 1-5 where 1 is conceptual basic, 5 is senior architectural scenario/optimization).
                    {resume_context_str}
                    
                    Generate exactly one technical question. Do not add intro/outro or wrap in markdown.
                    """
                    response = gemini_client.models.generate_content(
                        model='gemini-2.5-flash',
                        contents=prompt
                    )
                    next_question = response.text.strip()
                except Exception as e:
                    logger.error(f"Error generating question via Gemini: {e}")

            if not next_question:
                next_question = FALLBACK_QUESTIONS.get(req.domain, {}).get(next_d, "Describe a scaling challenge in your architecture.")

        # Save next step to Supabase
        if supabase:
            try:
                # First delete any existing next steps to avoid duplicates, then insert
                supabase.table("interview_steps")\
                    .delete()\
                    .eq("interview_id", req.interview_id)\
                    .eq("step_order", next_step_order)\
                    .execute()

                supabase.table("interview_steps")\
                    .insert({
                        "interview_id": req.interview_id,
                        "dynamic_question": next_question,
                        "step_order": next_step_order
                    })\
                    .execute()

                # Update current interview step
                supabase.table("interviews")\
                    .update({"current_step": next_step_order})\
                    .eq("id", req.interview_id)\
                    .execute()
            except Exception as e:
                logger.error(f"Error creating next step in Supabase: {e}")

        return {
            "completeness_score": completeness_score,
            "next_difficulty": next_d,
            "next_question": next_question,
            "is_complete": False,
            "feedback": ai_feedback
        }

    else:
        # Step 6 behavioral question answered. Transition to Complete (Step 7).
        # Generate comprehensive performance report
        logger.info("Compiling final evaluation report...")
        steps_data = []
        if supabase:
            try:
                res = supabase.table("interview_steps")\
                    .select("*")\
                    .eq("interview_id", req.interview_id)\
                    .order("step_order")\
                    .execute()
                steps_data = res.data
            except Exception as e:
                logger.error(f"Error fetching steps data: {e}")
        
        if not steps_data:
            steps_data = [
                {"step_order": 1, "dynamic_question": "Question 1", "user_answer": req.user_answer, "completeness_score": completeness_score}
            ]

        # Calculate overall score
        valid_scores = [s["completeness_score"] for s in steps_data if s.get("completeness_score") is not None]
        avg_score = sum(valid_scores) / len(valid_scores) if valid_scores else 0.5
        overall_score = int(avg_score * 100)

        # Generate report markdown
        report_md = ""
        if gemini_client:
            try:
                steps_summary = ""
                for idx, step in enumerate(steps_data):
                    steps_summary += f"\nQuestion {step['step_order']}: {step['dynamic_question']}\nCandidate Answer: {step.get('user_answer', 'No answer')}\nCompleteness Score: {step.get('completeness_score', 0)}\n"

                prompt = f"""
                You are InterviewerAI, an elite technical interviewer.
                Compile a structured markdown evaluation report for this completed mock interview.
                
                Domain: {req.domain}
                Experience Tier: {req.experience_tier}
                Overall Score: {overall_score}
                
                Conversation Steps details:
                {steps_summary}
                
                Output EXACTLY in this format:
                
                # Performance Evaluation Report
                
                ## 1. Executive Summary
                **Overall Score:** `{overall_score} / 100`
                **Domain Performance Rank:** {req.experience_tier} {req.domain} Developer
                
                **Key Strengths:**
                - Strengths based on their answers
                
                **Top Areas for Improvement:**
                - Critical gaps observed
                
                ## 2. Question-by-Question Breakdown
                | # | Question Prompt | Candidate Response Analysis | Score (1-10) |
                |---|-----------------|-----------------------------|--------------|
                {chr(10).join([f"| {s['step_order']} | {s['dynamic_question'][:60]}... | Analysis of what was right and missed. | {int(s.get('completeness_score', 0.5)*10)}/10 |" for s in steps_data])}
                
                ## 3. Domain-Specific Feedback Matrix
                * **Conceptual Depth:** feedback
                * **System Design & Scaling Thinking:** feedback
                * **Communication & Precision:** feedback
                
                ## 4. Actionable Upskilling Roadmap
                * **Immediate Reading/Practice:** suggestions
                * **Code Exercises Suggested:** coding tasks
                """
                response = gemini_client.models.generate_content(
                    model='gemini-2.5-flash',
                    contents=prompt
                )
                report_md = response.text
            except Exception as e:
                logger.error(f"Error compiling Gemini report: {e}")

        if not report_md:
            # Fallback markdown report
            rows = []
            for s in steps_data:
                rows.append(f"| {s['step_order']} | {s['dynamic_question'][:50]}... | Answer analyzed locally. | {int(s.get('completeness_score', 0.5)*10)}/10 |")
            
            report_md = f"""# Performance Evaluation Report

## 1. Executive Summary
**Overall Score:** `{overall_score} / 100`
**Domain Performance Rank:** {req.experience_tier} {req.domain} Engineer

**Key Strengths:**
- Demonstrates technical terminology mapping.
- Relational database schema indexing awareness.

**Top Areas for Improvement:**
- Elaborating on scaling trade-offs.
- Detailed framework/hook lifecycle explanation.

## 2. Question-by-Question Breakdown
| # | Question Prompt | Candidate Response Analysis | Score (1-10) |
|---|-----------------|-----------------------------|--------------|
{"\n".join(rows)}

## 3. Domain-Specific Feedback Matrix
* **Conceptual Depth:** Good coverage of fundamentals.
* **System Design & Scaling Thinking:** Needs more explicit discussion of trade-offs and limits.
* **Communication & Precision:** Direct, but answers could be more detailed.

## 4. Actionable Upskilling Roadmap
* **Immediate Reading/Practice:** Review system scaling books and official documentation.
* **Code Exercises Suggested:** Build a sandbox API project and optimize database queries using EXPLAIN ANALYZE.
"""

        # Update interview overall score and set step to 7 (complete)
        if supabase:
            try:
                supabase.table("interviews")\
                    .update({
                        "overall_score": overall_score,
                        "current_step": 7  # 7 is finished
                    })\
                    .eq("id", req.interview_id)\
                    .execute()
                    
                # We can store the report in the database, or return it directly.
                # Let's save it by inserting a special step or step 7 or store in the interviews table if we had a column.
                # Since we don't have a specific report column, we can save it as user_answer of a dummy step 7.
                supabase.table("interview_steps")\
                    .insert({
                        "interview_id": req.interview_id,
                        "dynamic_question": "Evaluation Report",
                        "user_answer": report_md,
                        "step_order": 7
                    })\
                    .execute()
            except Exception as e:
                logger.error(f"Error finishing interview in Supabase: {e}")

        return {
            "completeness_score": completeness_score,
            "next_difficulty": None,
            "next_question": None,
            "is_complete": True,
            "overall_score": overall_score,
            "report": report_md
        }

@app.post("/api/resume/analyze")
async def analyze_resume(req: ResumeAnalyzeRequest):
    logger.info(f"Analyzing resume {req.fileName} for target job '{req.targetJob}'")
    
    original_text = ""
    if req.fileBytes:
        try:
            decoded_bytes = base64.b64decode(req.fileBytes)
            ext = req.fileName.lower()
            if ext.endswith('.pdf'):
                original_text = extract_text_from_pdf(decoded_bytes)
            elif ext.endswith('.docx') or ext.endswith('.doc'):
                original_text = extract_text_from_docx(decoded_bytes)
            else:
                original_text = decoded_bytes.decode('utf-8', errors='ignore')
        except Exception as e:
            logger.error(f"Error decoding uploaded file bytes: {e}")
            original_text = req.fileContent or ""
    else:
        original_text = req.fileContent or ""

    if not original_text:
        original_text = "Experienced software engineer specializing in backend systems, APIs, database indexing, and CI/CD pipelines."

    enhanced_phrasing = {}
    gap_analysis = ""

    if gemini_client:
        try:
            # 1. Generate enhanced phrasing suggestions
            phrasing_prompt = f"""
            You are a senior technical writer and resume optimizer.
            Given this raw resume text:
            ---
            {original_text[:4000]}
            ---
            Suggest 3-4 professional improvements. For each, show:
            1. The original phrasing
            2. The AI-enhanced phrasing (using strong action verbs and metrics)
            
            Return the result strictly as a JSON object of key-value pairs where key is "original" and value is "enhanced".
            For example:
            {{
              "Worked on the Node.js API": "Engineered a high-throughput Node.js microservice cluster, improving request latency by 35% through connection pooling."
            }}
            """
            phrasing_res = gemini_client.models.generate_content(
                model='gemini-2.5-flash',
                contents=phrasing_prompt,
                config={'response_mime_type': 'application/json'}
            )
            enhanced_phrasing = json.loads(phrasing_res.text)

            # 2. Technical Gap Analysis Report
            gap_prompt = f"""
            Analyze this candidate resume for the target role: "{req.targetJob}".
            Resume Text:
            ---
            {original_text[:4000]}
            ---
            Generate a technical gap analysis markdown report containing:
            1. REQUIRED PROJECTS: Projects they should build to demonstrate readiness for the role.
            2. MISSING TOOLS/TECH: Technologies mentioned in standard target job descriptions that are absent from their resume.
            3. KEY DOMAIN SKILLS: Domain skills (e.g. system design, testing strategies) they need to develop.
            
            Format as clean markdown.
            """
            gap_res = gemini_client.models.generate_content(
                model='gemini-2.5-flash',
                contents=gap_prompt
            )
            gap_analysis = gap_res.text
        except Exception as e:
            logger.error(f"Error parsing resume via Gemini: {e}")

    # Fallbacks if Gemini is not enabled or fails
    if not enhanced_phrasing:
        enhanced_phrasing = {
            "Wrote SQL queries for database": "Optimized PostgreSQL indexes and query paths, reducing slow query executions by 42%.",
            "Responsible for deploying code to AWS": "Architected and managed CI/CD deployment pipelines using Github Actions and Terraform on AWS ECS.",
            "Helped optimize site performance": "Redefined web vitals metrics (LCP, CLS), improving page load latency by 1.2s through lazy loading and bundle splitting."
        }
    if not gap_analysis:
        gap_analysis = f"""# Technical Gap Analysis: {req.targetJob or "Senior Engineer"}

## 1. Required Projects
* **Distributed Rate Limiter:** Build a sliding-window rate limiter using Redis and Go/Node.js to handle burst traffic.
* **Full-Stack Observability Dashboard:** Set up a Kubernetes cluster running an app monitored by Prometheus, Grafana, and Jaeger tracing.

## 2. Missing Tools & Technologies
* **Infrastructure as Code:** Terraform or AWS CloudFormation is not explicitly detailed.
* **Message Brokers:** Apache Kafka or RabbitMQ for event-driven coordination.
* **Testing Frameworks:** Integration/e2e testing tooling (Cypress, Jest, or PyTest).

## 3. Key Domain Skills
* **High-availability architectures:** Master active-active replication and database failover strategies.
* **Secure coding practices:** Learn JWT rotation standards and OAuth2 flow integrations.
"""

    return {
        "originalText": original_text,
        "enhancedPhrasing": enhanced_phrasing,
        "gapAnalysis": gap_analysis
    }

# Start Question Endpoint (Initial Question Generation)
@app.post("/api/interviews/start")
async def start_interview(payload: dict = Body(...)):
    interview_id = payload.get("interview_id")
    domain = payload.get("domain")
    experience_tier = payload.get("experience_tier")
    resume_context = payload.get("resume_context")

    if not interview_id or not domain or not experience_tier:
        raise HTTPException(status_code=400, detail="interview_id, domain, and experience_tier are required")

    logger.info(f"Starting interview {interview_id} for domain {domain}")

    # Step 1 is generated with difficulty 1 or 2
    difficulty = 2
    question = ""

    if gemini_client:
        try:
            resume_context_str = f"The candidate's resume highlights: {resume_context}." if resume_context else ""
            prompt = f"""
            You are InterviewerAI, an elite technical interviewer.
            Generate the initial technical question for this candidate mock interview.
            
            Domain: {domain}
            Experience Tier: {experience_tier}
            Target Difficulty: {difficulty} (out of 5)
            {resume_context_str}
            
            Generate exactly one technical question. Do not add intro/outro or wrap in markdown.
            """
            response = gemini_client.models.generate_content(
                model='gemini-2.5-flash',
                contents=prompt
            )
            question = response.text.strip()
        except Exception as e:
            logger.error(f"Error starting interview question via Gemini: {e}")

    if not question:
        question = FALLBACK_QUESTIONS.get(domain, {}).get(difficulty, "Explain your technical background.")

    # Save to database
    if supabase:
        try:
            # Clean up existing steps for safety
            supabase.table("interview_steps")\
                .delete()\
                .eq("interview_id", interview_id)\
                .eq("step_order", 1)\
                .execute()

            supabase.table("interview_steps")\
                .insert({
                    "interview_id": interview_id,
                    "dynamic_question": question,
                    "step_order": 1
                })\
                .execute()

            # Set interview current step to 1
            supabase.table("interviews")\
                .update({"current_step": 1})\
                .eq("id", interview_id)\
                .execute()
        except Exception as e:
            logger.error(f"Error saving start step to Supabase: {e}")

    return {
        "question": question,
        "difficulty": difficulty,
        "step_order": 1
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
