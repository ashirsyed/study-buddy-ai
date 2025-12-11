# Study Buddy AI

An AI-powered quiz generation application built with Streamlit and Groq LLM.

## Features

- 🎯 Generate multiple-choice questions
- ✍️ Generate fill-in-the-blank questions
- 📊 Track quiz results and scores
- 💾 Export results to CSV
- 🚀 Easy deployment to GCP

## Quick Start

### Local Development

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd STUDY-BUDDY-AI
   ```

2. **Setup environment**
   ```bash
   cp env.example .env
   # Edit .env and add your GROQ_API_KEY (get it from https://console.groq.com/)
   ```

3. **Run locally**
   ```bash
   chmod +x start.sh
   ./start.sh
   ```

   The application will be available at `http://localhost:8501`

For detailed local setup instructions, see [LOCAL_SETUP.md](LOCAL_SETUP.md)

## Deployment

### Quick Deploy to GCP (Cloud Run)

The fastest way to deploy to GCP:

```bash
# 1. Setup .env file
cp env.example .env
# Edit .env and add GCP_PROJECT_ID and GROQ_API_KEY

# 2. Deploy
chmod +x deploy.sh
./deploy.sh
```

For detailed instructions, see [QUICK_DEPLOY_GCP.md](QUICK_DEPLOY_GCP.md)

### Production Deployment (Kubernetes + ArgoCD + Jenkins)

For production deployments with full CI/CD on GCP VM:

1. **First**: Follow [VM_SETUP_GCP.md](VM_SETUP_GCP.md) to create and configure your VM
2. **Then**: Follow [DETAILED_DEPLOYMENT.md](DETAILED_DEPLOYMENT.md) for Kubernetes setup
3. **Quick Reference**: See [QUICK_START_VM.md](QUICK_START_VM.md) for condensed steps

## Project Structure

```
STUDY-BUDDY-AI/
├── application.py              # Main Streamlit application
├── src/
│   ├── config/                 # Configuration settings
│   ├── generator/              # Question generation logic
│   ├── llm/                    # LLM client (Groq)
│   ├── models/                 # Pydantic models
│   ├── prompts/                # Prompt templates
│   └── utils/                  # Helper utilities
├── manifests/                  # Kubernetes manifests
│   ├── deployment.yaml
│   └── service.yaml
├── scripts/                    # Helper scripts
│   ├── build-and-push.sh
│   └── setup-k8s.sh
├── requirements.txt            # Python dependencies
├── Dockerfile                  # Docker configuration
├── Jenkinsfile                 # Jenkins CI/CD pipeline
├── start.sh                    # Local start script
├── deploy.sh                   # Quick GCP deployment
└── env.example                 # Environment variables template
```

## Environment Variables

Create a `.env` file from `env.example`:

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `GROQ_API_KEY` | Your Groq API key | Yes | - |
| `MODEL_NAME` | LLM model to use | No | llama-3.1-8b-instant |
| `TEMPERATURE` | Model temperature | No | 0.9 |
| `MAX_RETRIES` | Max retry attempts | No | 3 |
| `GCP_PROJECT_ID` | GCP project ID | For GCP deployment | - |
| `GCP_REGION` | GCP region | For GCP deployment | us-central1 |

## Dependencies

- Python 3.10+
- Streamlit
- LangChain (Groq integration)
- Pydantic
- Pandas

See `requirements.txt` for complete list.

## Documentation

- [Local Setup Guide](LOCAL_SETUP.md) - Run locally
- [Quick Deploy to GCP](QUICK_DEPLOY_GCP.md) - Fast GCP deployment
- [Detailed Deployment](DETAILED_DEPLOYMENT.md) - Production setup with K8s/ArgoCD/Jenkins

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

[Add your license here]

## Support

For issues and questions, please open an issue on GitHub.

