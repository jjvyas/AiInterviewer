import re

# Domain competency keywords and concepts
DOMAIN_KEYWORDS = {
    "Frontend": [
        "virtual dom", "dom", "lifecycle", "hook", "usememo", "usecallback", "useeffect",
        "redux", "context api", "zustand", "recoil", "rendering path", "code splitting",
        "lazy loading", "web vitals", "lcp", "fid", "cls", "ssr", "ssg", "isr", "xss", "csrf",
        "state", "props", "component", "react", "vue", "rendering"
    ],
    "Backend": [
        "restful", "graphql", "n+1", "grpc", "websocket", "sql", "postgresql", "mysql",
        "nosql", "mongodb", "redis", "acid", "isolation", "index", "b-tree", "gin",
        "concurrency", "event loop", "pooling", "cache", "rabbitmq", "kafka", "microservice",
        "join", "query", "database", "api", "hashing", "http", "transaction"
    ],
    "Full-Stack": [
        "jwt", "oauth2", "cookie", "http-only", "hydration", "optimistic ui", "latency",
        "query optimization", "bundle", "integration", "database", "frontend", "backend",
        "api", "cookies", "cors", "validation", "state", "props"
    ],
    "DevOps": [
        "ci/cd", "blue-green", "canary", "rolling", "github actions", "jenkins",
        "docker", "kubernetes", "pod", "deployment", "ingress", "terraform",
        "prometheus", "grafana", "elk", "sla", "slo", "sli",
        "git", "pipeline", "ssh", "variables", "deploy"
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
        "Junior": {
            1: "Explain the difference between state and props in React or Vue. When would you use one over the other?",
            2: "What is prop drilling, and how does the Context API or basic state providers help solve it?",
            3: "What are the core differences between local state, session storage, and local storage on the browser?",
            4: "What is the difference between client-side rendering (CSR) and server-side rendering (SSR) at a basic conceptual level?",
            5: "How do you style components in a modern framework? Compare standard CSS/SASS with utility-first frameworks like Tailwind."
        },
        "Mid": {
            1: "Explain the difference between the Virtual DOM and the Real DOM. How does React or Vue use it to optimize rendering?",
            2: "What is prop drilling, and what are the main state management strategies (e.g., Context API, Zustand) you would use to mitigate it?",
            3: "Explain the Critical Rendering Path. How do tools like code splitting and lazy loading improve Core Web Vitals like LCP?",
            4: "What is Cross-Site Scripting (XSS) in frontend applications? How do you securely mitigate XSS and CSRF risks when storing authentication tokens?",
            5: "Design a high-performance, real-time dashboards frontend that must update charts every 100ms. Detail your components rendering, rendering optimizations (useMemo/useCallback), and web-socket subscription state strategy."
        },
        "Senior": {
            1: "How does React's Fiber architecture or Vue's reactivity system manage scheduling and rendering priorities? Explain how to avoid blocking the main thread during heavy computations.",
            2: "Design a state management architecture for a large offline-first dashboard. How do you handle optimistic updates, local persistence (IndexedDB), and server synchronization conflicts?",
            3: "Analyze the impact of Server Components (RSC) and Hydration on modern web performance. How do you resolve hydration mismatch errors in production?",
            4: "Explain advanced security protocols for frontend applications. How do you configure Content Security Policy (CSP), handle token rotation securely, and mitigate clickjacking?",
            5: "Architect a micro-frontend shell application. How do you handle shared state, coordinate routing between micro-apps, manage dependency version clashes, and ensure independent deployment pipelines?"
        },
        "Lead": {
            1: "How do you establish code quality standards, design system governance, and automated performance budgets across multiple frontend engineering teams?",
            2: "Explain your strategy for migrating a legacy monolithic frontend to a modern framework without interrupting feature delivery. How do you manage technical debt and assess risk?",
            3: "Design an end-to-end telemetry system for tracking Core Web Vitals, runtime frontend errors, and user interactions in a global, high-traffic web application.",
            4: "How do you evaluate and integrate third-party dependencies or design-system frameworks? Explain the security, accessibility (a11y), and performance trade-offs you look for.",
            5: "Architect a continuous delivery flow for a frontend application served globally. Detail CDN caching rules, edge routing (e.g., Cloudflare Workers for A/B testing), rollback strategies, and zero-downtime deployments."
        }
    },
    "Backend": {
        "Junior": {
            1: "What is the difference between an INNER JOIN and a LEFT JOIN in SQL, and when would you use each?",
            2: "Explain the difference between HTTP GET and POST requests. What are the common status codes returned by a REST API?",
            3: "What is database normalization? Explain the difference between 1NF, 2NF, and 3NF with a basic database example.",
            4: "What is an ORM (Object-Relational Mapping)? What are the pros and cons of using an ORM versus writing raw SQL?",
            5: "How do you securely store user passwords in a database? What hashing algorithms should you use and why is salting important?"
        },
        "Mid": {
            1: "In a relational database like PostgreSQL, what is the difference between a B-Tree index and a Hash index, and when would you prefer one over the other?",
            2: "Explain the N+1 query problem in database ORMs/GraphQL. How do you identify it, and what strategies do you use to resolve it?",
            3: "Describe the Node.js event loop. How does it handle concurrency differently compared to multi-threaded engines, and how do you prevent blocking it?",
            4: "Compare Cache-aside and Write-through caching strategies. Detail the concurrency challenges (e.g., cache stampede, race conditions) and how you design to prevent them.",
            5: "Design a highly-scalable, asynchronous order processing system that can handle 100,000 requests/second. Detail your queue/broker setup (Kafka vs RabbitMQ), concurrency pooling, scaling, and database ACID transaction boundaries."
        },
        "Senior": {
            1: "Compare optimistic and pessimistic concurrency control in highly contested database systems. How do you handle deadlocks and write conflicts?",
            2: "Explain database sharding, partition keys selection, and the architectural trade-offs of using distributed databases like Spanner or CockroachDB over standard PostgreSQL replication.",
            3: "How do you implement the Saga pattern for managing distributed transactions across multiple microservices? Compare orchestration vs. choreography approaches.",
            4: "Detail how you would implement a multi-level caching system. How do you prevent cache penetration, cache breakdown, and cache stampedes under heavy traffic spikes?",
            5: "Design a high-frequency real-time notification engine. Explain your choices of transport protocols (WebSockets, SSE, gRPC), connection scaling, horizontal distribution, and persistent connection storage."
        },
        "Lead": {
            1: "How do you define and enforce service boundaries, domain-driven design (DDD) standards, and API versioning strategies across a large engineering organization?",
            2: "Explain your strategy for migrating a complex, legacy on-premise backend to a microservices architecture. How do you ensure zero-downtime, data consistency, and developer velocity?",
            3: "Design an enterprise-wide observability framework. How do you standardize distributed tracing, structured logging, and metrics aggregation across diverse technology stacks?",
            4: "How do you handle data governance, privacy compliance (GDPR/CCPA), and security audits in a backend ecosystem that processes millions of transactions?",
            5: "Architect a highly resilient cloud-native infrastructure capable of active-active multi-region deployment. Detail failover protocols, data replication lag handling, and global load balancing."
        }
    },
    "Full-Stack": {
        "Junior": {
            1: "Explain how the frontend communicates with the backend. What is JSON, and how do you handle basic API response errors on the UI?",
            2: "What are cookies, and how are they used to keep a user logged in across page refreshes?",
            3: "What is CORS (Cross-Origin Resource Sharing)? Why does the browser block requests, and how do you resolve it?",
            4: "Explain the difference between client-side validation and server-side validation. Why is server-side validation always required?",
            5: "How do you structure a simple full-stack app database? Design a basic schema for a blog (users, posts, comments)."
        },
        "Mid": {
            1: "Explain how session-based authentication differs from JWT-based authentication. Which headers or cookies are involved in securing them?",
            2: "What is client-side data hydration? How do you synchronize server-rendered HTML state with client-side state without causing layout shifts or duplicate API requests?",
            3: "Explain how you would implement optimistic UI updates on a collaborative board application. What happens if the server operation fails?",
            4: "How do you optimize network latency and resource delivery in a full-stack application (e.g. bundle size minimization, API responses, database query optimization)?",
            5: "Design a real-time collaborative document editor (like Google Docs). Explain the end-to-end data flow, state sync, database schema, and security rules."
        },
        "Senior": {
            1: "Compare BFF (Backend-for-Frontend) architecture with a unified GraphQL gateway. How do you manage schema federation, caching, and rate limiting in the gateway?",
            2: "Design a server-side rendering (SSR) pipeline with edge caching. How do you implement dynamic personalization without breaking CDN cache ratios?",
            3: "Explain how you would design a secure, cross-domain single-sign-on (SSO) flow using OAuth2 and OpenID Connect, securing tokens in the browser.",
            4: "How do you implement real-time collaborative state sync using CRDTs (Conflict-free Replicated Data Types) or OT (Operational Transformation)? Compare the architectural trade-offs.",
            5: "Design a complete end-to-end streaming media application. Explain storage caching, edge delivery, dynamic transcoding, metadata storage, and candidate playback analytics integration."
        },
        "Lead": {
            1: "How do you align frontend and backend engineering cycles, standardizing API contracts (e.g. OpenAPI, ProtoBuf) and testing flows (e.g. contract testing)?",
            2: "Explain your strategy for maintaining high-availability, scalability, and disaster recovery of a full-stack product during major global events or cloud provider outages.",
            3: "Design an end-to-end developer experience (DevEx) system from local sandbox environment running Docker/Tilt to automated preview environments on pull requests.",
            4: "How do you design, monitor, and scale authentication, authorization, and permission checks across hundreds of services and different client applications?",
            5: "Architect a scalable web platform hosting millions of user-generated content pages. Detail SEO optimizations, edge hydration, internationalization (i18n), dynamic rendering, and caching."
        }
    },
    "DevOps": {
        "Junior": {
            1: "What is Git, and what is the difference between a merge and a rebase? Explain a basic branching strategy.",
            2: "What is Docker, and why is it containerization useful? Explain how to write a basic Dockerfile to containerize a web app.",
            3: "What is a CI/CD pipeline in simple terms? What steps would you put in a pipeline to deploy a web application?",
            4: "What is SSH, and how do you use key pairs to securely access a remote Linux server?",
            5: "What are environment variables, and why should you never commit API keys or passwords directly to Git?"
        },
        "Mid": {
            1: "What is a CI/CD pipeline, and what are the differences between Blue-Green, Canary, and Rolling deployment strategies?",
            2: "Explain the difference between a Docker container and a Kubernetes Pod. What role do Ingress and Services play in pod communication?",
            3: "What is Infrastructure as Code (IaC)? How does Terraform manage environment state, and why is locking the state file critical in a team environment?",
            4: "Describe the difference between Prometheus and the ELK stack. How do you define and track SLAs, SLOs, and SLIs for a payment service?",
            5: "Design an automated, self-healing Kubernetes deployment architecture that scales dynamically based on CPU/Memory thresholds. Include your multi-stage Docker build, CI/CD pipeline, and Prometheus alerts configuration."
        },
        "Senior": {
            1: "How do you build a secure GitOps deployment pipeline using ArgoCD or Flux? Explain how secret management (e.g. HashiCorp Vault, Sealed Secrets) is handled.",
            2: "Design a service mesh architecture using Istio. Explain mutual TLS, traffic shifting, rate limiting, and observability across namespaces.",
            3: "Explain how you would write and structure reusable, multi-environment Terraform modules. How do you handle disaster recovery of Terraform state and lock files?",
            4: "Detail how you would configure a highly available Prometheus and Thanos monitoring cluster for long-term storage and cross-cluster query aggregation.",
            5: "Design an enterprise-level, secure, and isolated multi-tenant Kubernetes architecture. Explain Network Policies, RBAC, OPA Gatekeeper, and node selection standards."
        },
        "Lead": {
            1: "How do you build and foster a DevOps culture across an engineering team? Explain how you measure and optimize DORA metrics.",
            2: "Explain your strategy for migrating a complex, legacy on-premise infrastructure to a hybrid or multi-cloud ecosystem with zero downtime.",
            3: "Design an enterprise-level disaster recovery and business continuity plan. Detail RTO, RPO, backups validation, and failover/failback runs.",
            4: "How do you establish security standards, compliance (e.g., SOC2, PCI-DSS), and automated vulnerability scanning across all stages of the software supply chain?",
            5: "Architect a global-scale cloud platform with automated cost-optimization controls, budget alerts, auto-scaling thresholds, and multi-cloud management."
        }
    }
}

BEHAVIORAL_QUESTIONS = {
    "Frontend": {
        "Junior": "Tell me about a project you worked on where you made a mistake. How did you handle it and what did you learn?",
        "Mid": "Tell me about a time when you had to optimize a legacy codebase with significant technical debt. How did you balance delivering new features while refactoring UI components, and how did you measure success?",
        "Senior": "Describe a complex technical conflict you resolved in a frontend team. What were the trade-offs, and how did you build alignment?",
        "Lead": "Tell me about a time you mentored a junior team member or led a major architectural migration. How did you influence the team and manage stakeholder expectations?"
    },
    "Backend": {
        "Junior": "Tell me about a time you had to learn a new programming language or tool quickly to complete a task. How did you go about it?",
        "Mid": "Describe a production outage or critical database performance bottleneck you encountered. How did you diagnose the issue, resolve it under pressure, and what post-mortem actions did you implement?",
        "Senior": "Tell me about a time when you had to make a high-stakes architectural decision with incomplete information. What was the decision, how did you evaluate the risks, and what was the outcome?",
        "Lead": "Describe how you led a cross-functional team through a major system redesign or database migration. How did you communicate risks, coordinate tasks, and keep the team motivated?"
    },
    "Full-Stack": {
        "Junior": "Tell me about a full-stack project you are most proud of. What was your role, and what challenges did you overcome?",
        "Mid": "Tell me about a project where you had to bridge the gap between complex database capabilities and client-side performance. How did you coordinate with product managers or frontend engineers, and how did you resolve technical conflicts?",
        "Senior": "Describe a time when you had to optimize end-to-end latency for a highly transactional feature. How did you balance the changes between frontend rendering and backend storage optimization?",
        "Lead": "Explain how you set engineering standards, API guidelines, and deployment practices for a full-stack team. How did you resolve developer friction and technical debt issues?"
    },
    "DevOps": {
        "Junior": "Tell me about a time you struggled with a deployment or build pipeline error. What steps did you take to troubleshoot and resolve it?",
        "Mid": "Explain how you handled a scenario where a deployment broke production despite passing all staging automated tests. How did you rollback, how did you audit the pipeline failure, and how did you secure alignment with the dev team?",
        "Senior": "Describe a time you architected the migration of a legacy infrastructure to a modern CI/CD flow. How did you ensure security, minimize downtime, and train other developers?",
        "Lead": "Tell me about a major security incident or complete cloud provider outage you had to manage. How did you lead the recovery effort, coordinate stakeholders, and implement structural prevention measures?"
    }
}

def analyze_answer_keywords(answer: str, question: str, domain: str, experience_tier: str = "Mid") -> dict:
    """
    Computes Completeness Score C based on the mathematical rubric adapted to the experience tier:
    - Junior: evaluated mainly on keywords/correctness (kw_score).
    - Mid: keywords + architecture or tradeoffs.
    - Senior / Lead: full evaluation of keywords + architecture + tradeoffs.
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
            
    # Also parse question keywords that might be in answer (length >= 3 and not a common stop word)
    stop_words = {
        "what", "difference", "between", "when", "would", "each", "explain", "where",
        "which", "with", "from", "their", "there", "these", "those", "your", "about",
        "have", "does", "doing", "done", "been", "being", "were", "are", "the", "and",
        "but", "for", "you", "our", "him", "his", "her", "she", "its", "they", "them",
        "than", "then", "only", "very", "just", "more", "most", "some", "such", "than",
        "through", "until", "very", "while", "with", "would", "your", "yourself", "yourselves"
    }
    q_words = [w.lower() for w in re.findall(r'\w+', question) if len(w) >= 3 and w.lower() not in stop_words]
    q_matches = 0
    for qw in q_words:
        if qw in ans_lower:
            q_matches += 1
            
    kw_score = min(3, kw_matches + q_matches)

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

    # Calculate C based on tier expectations
    if experience_tier == "Junior":
        # Junior level shouldn't be penalized for missing architecture and tradeoffs
        bonus_score = min(1.0, (arch_score + trade_score) * 0.5)
        completeness = round(min(1.0, (kw_score / 3.0) + bonus_score), 2)
    elif experience_tier == "Mid":
        # Mid level expects core keywords + some architectural/trade-off thinking
        total_score = kw_score + min(3, arch_score + trade_score)
        completeness = round(total_score / 6.0, 2)
    else:
        # Senior / Lead requires depth in all areas
        total_score = kw_score + arch_score + trade_score
        completeness = round(total_score / 9.0, 2)
        
    # Baseline floor: if they wrote a coherent response with > 12 words, they should score at least 40% (0.40)
    # instead of getting marked 10% just because they didn't include Senior scaling buzzwords.
    if completeness < 0.40 and len(ans_lower.split()) >= 12:
        # Check if they actually attempted to answer (contain at least some key context)
        if kw_score >= 1 or q_matches >= 1:
            completeness = 0.40

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
