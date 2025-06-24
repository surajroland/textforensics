from fastapi import FastAPI

app = FastAPI(title="TextForensics API")


@app.get("/")
def root():
    return {"message": "TextForensics API"}


@app.get("/health")
def health():
    return {"status": "healthy"}
