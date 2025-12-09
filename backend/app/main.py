'''
@Abed
 to download the depedencies  read the requirements.txt file 
'''


from fastapi import FastAPI
from app.api.routes import auth, chat, users, health

app = FastAPI(title="Flutter + FastAPI + OpenAI")

app.include_router(health.router)
app.include_router(users.router)
app.include_router(chat.router)
app.include_router(auth.router)
