import re

# Domain competency keywords and concepts
DOMAIN_KEYWORDS = {
    "Frontend": [
        "virtual dom", "dom", "lifecycle", "hook", "usememo", "usecallback", "useeffect",
        "redux", "context api", "zustand", "recoil", "rendering path", "code splitting",
        "lazy loading", "web vitals", "lcp", "fid", "cls", "ssr", "ssg", "isr", "xss", "csrf"
    ],
    "Backend": [
        "restful", "graphql", "n+1", "grpc", "websocket", "sql", "postgresql", "mysql",
        "nosql", "mongodb", "redis", "acid", "isolation", "index", "b-tree", "gin",
        "concurrency", "event loop", "pooling", "cache", "rabbitmq", "kafka", "microservice"
    ],
    "Full-Stack": [
        "jwt", "oauth2", "cookie", "http-only", "hydration", "optimistic ui", "latency",
        "query optimization", "bundle", "integration", "database", "frontend", "backend"
    ],
    "DevOps": [
        "ci/cd", "blue-green", "canary", "rolling", "github actions", "jenkins",
        "docker", "kubernetes", "pod", "deployment", "ingress", "terraform",
        "prometheus", "grafana", "elk", "sla", "slo", "sli"
    ]
}

ARCHITECTURAL_KEYWORDS = [
    "architecture", "scaling", "redundancy", "concurrency", "bottleneck", 
    "latency", "throughput", "separation of concerns", "cache", "broker", 
    "layer", "load balancer", "failover", "index", "structure", "schema"
]

TRADE_OFF_KEYWORDS = [
    "trade-off", "tradeoff", "compromise", "pros and cons", "whereas", 
    "however", "on the other hand", "advantage", "disadvantage", "benefit", 
    "drawback", "alternative", "cost", "overhead", "flexibility"
]

# Static Question Bank for fallback and local testing (1 to 5 difficulty ranks)
FALLBACK_QUESTIONS = {
    "Frontend": {
        1: "Explain the difference between the Virtual DOM and the Real DOM. How does React or Vue use it to optimize rendering?",
        2: "What is prop drilling, and what are the main state management strategies (e.g., Context API, Zustand) you would use to mitigate it?",
        3: "Explain the Critical Rendering Path. How do tools like code splitting and lazy loading improve Core Web Vitals like LCP?",
        4: "What is Cross-Site Scripting (XSS) in frontend applications? How do you securely mitigate XSS and CSRF risks when storing authentication tokens?",
        5: "Design a high-performance, real-time dashboards frontend that must update charts every 100ms. Detail your components rendering, rendering optimizations (useMemo/useCallback), and web-socket subscription state strategy."
    },
    "Backend": {
        1: "In a relational database like PostgreSQL, what is the difference between a B-Tree index and a Hash index, and when would you prefer one over the other?",
        2: "Explain the N+1 query problem in database ORMs/GraphQL. How do you identify it, and what strategies do you use to resolve it?",
        3: "Describe the Node.js event loop. How does it handle concurrency differently compared to multi-threaded engines, and how do you prevent blocking it?",
        4: "Compare Cache-aside and Write-through caching strategies. Detail the concurrency challenges (e.g., cache stampede, race conditions) and how you design to prevent them.",
        5: "Design a highly-scalable, asynchronous order processing system that can handle 100,000 requests/second. Detail your queue/broker setup (Kafka vs RabbitMQ), concurrency pooling, scaling, and database ACID transaction boundaries."
    },
    "Full-Stack": {
        1: "Explain how session-based authentication differs from JWT-based authentication. Which headers or cookies are involved in securing them?",
        2: "What is client-side data hydration? How do you synchronize server-rendered HTML state with client-side state without causing layout shifts or duplicate API requests?",
        3: "Explain how you would implement optimistic UI updates on a collaborative board application. What happens if the server operation fails?",
        4: "How do you optimize network latency and resource delivery in a full-stack application (e.g. bundle size minimization, API responses, database query optimization)?",
        5: "Design a real-time collaborative document editor (like Google Docs). Explain the end-to-end data flow, state sync, database schema, and security rules."
    },
    "DevOps": {
        1: "What is a CI/CD pipeline, and what are the differences between Blue-Green, Canary, and Rolling deployment strategies?",
        2: "Explain the difference between a Docker container and a Kubernetes Pod. What role do Ingress and Services play in pod communication?",
        3: "What is Infrastructure as Code (IaC)? How does Terraform manage environment state, and why is locking the state file critical in a team environment?",
        4: "Describe the difference between Prometheus and the ELK stack. How do you define and track SLAs, SLOs, and SLIs for a payment service?",
        5: "Design an automated, self-healing Kubernetes deployment architecture that scales dynamically based on CPU/Memory thresholds. Include your multi-stage Docker build, CI/CD pipeline, and Prometheus alerts configuration."
    }
}

BEHAVIORAL_QUESTIONS = {
    "Frontend": "Tell me about a time when you had to optimize a legacy codebase with significant technical debt. How did you balance delivering new features while refactoring UI components, and how did you measure success?",
    "Backend": "Describe a production outage or critical database performance bottleneck you encountered. How did you diagnose the issue, resolve it under pressure, and what post-mortem actions did you implement?",
    "Full-Stack": "Tell me about a project where you had to bridge the gap between complex database capabilities and client-side performance. How did you coordinate with product managers or frontend engineers, and how did you resolve technical conflicts?",
    "DevOps": "Explain how you handled a scenario where a deployment broke production despite passing all staging automated tests. How did you rollback, how did you audit the pipeline failure, and how did you secure alignment with the dev team?"
}

def analyze_answer_keywords(answer: str, question: str, domain: str) -> dict:
    """
    Computes Completeness Score C based on the mathematical rubric:
    C = (Keywords Present + Architecture Mentioned + Trade-offs Explained) / Total Expected Criteria
    We will rate each component on a scale of 0 to 3, giving a max score of 9, normalized to [0, 1].
    """
    if not answer or len(answer.strip()) < 5:
        return {"completeness": 0.0, "keywords": 0, "architecture": 0, "tradeoffs": 0}

    ans_lower = answer.lower()
    
    # 1. Keywords Present (Matches of domain keywords or words in question)
    domain_kws = DOMAIN_KEYWORDS.get(domain, [])
    kw_matches = 0
    for kw in domain_kws:
        if kw in ans_lower:
            kw_matches += 1
            
    # Also parse question keywords that might be in answer
    q_words = [w.lower() for w in re.findall(r'\w+', question) if len(w) > 4]
    q_matches = 0
    for qw in q_words:
        if qw in ans_lower:
            q_matches += 1
            
    kw_score = min(3, (kw_matches + (1 if q_matches > 2 else 0)))

    # 2. Architecture Mentioned
    arch_matches = 0
    for kw in ARCHITECTURAL_KEYWORDS:
        if kw in ans_lower:
            arch_matches += 1
    arch_score = min(3, arch_matches)

    # 3. Trade-offs Explained
    trade_matches = 0
    for kw in TRADE_OFF_KEYWORDS:
        if kw in ans_lower:
            trade_matches += 1
    trade_score = min(3, trade_matches)

    # Calculate C
    total_score = kw_score + arch_score + trade_score
    completeness = round(total_score / 9.0, 2)
    
    return {
        "completeness": completeness,
        "keywords": kw_score,
        "architecture": arch_score,
        "tradeoffs": trade_score
    }

def adjust_difficulty(current_d: int, completeness: float) -> int:
    """
    If C >= 0.8: D_{n+1} = min(5, D_n + 1)
    If C <= 0.4: D_{n+1} = max(1, D_n - 1)
    Otherwise: D_{n+1} = D_n
    """
    if completeness >= 0.8:
        return min(5, current_d + 1)
    elif completeness <= 0.4:
        return max(1, current_d - 1)
    else:
        return current_d
