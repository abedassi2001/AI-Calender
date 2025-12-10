from dotenv import load_dotenv
import os

load_dotenv()  # This loads the .env file automatically

OPENAI_KEY = os.getenv("OPENAI_API_KEY")
