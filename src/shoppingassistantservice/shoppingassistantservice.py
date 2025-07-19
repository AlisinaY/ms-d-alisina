#!/usr/bin/python

import os
import psycopg2
from urllib.parse import unquote
from flask import Flask, request
from dotenv import load_dotenv  # NEU: Für .env Datei
from langchain_core.messages import HumanMessage
from langchain_openai import ChatOpenAI, OpenAIEmbeddings  # OpenAI GPT

# === Load environment variables ===
load_dotenv()  # Lädt die .env Datei automatisch

# === Get DB Credentials from .env ===
def get_db_credentials():
    creds = {
        "host": os.getenv("DB_HOST"),
        "database": os.getenv("DB_NAME"),
        "user": os.getenv("DB_USER"),
        "password": os.getenv("DB_PASS")
    }

    if not creds["host"]:
        raise ValueError("❌ Kein DB_HOST gefunden! Bitte prüfe deine .env Datei.")

    return creds

# === Connect to PostgreSQL (AWS RDS) ===
def get_postgres_connection():
    creds = get_db_credentials()

    conn = psycopg2.connect(
        host=creds['host'],
        database=creds['database'],
        user=creds['user'],
        password=creds['password']
    )
    return conn


# === Flask App ===
def create_app():
    app = Flask(__name__)

    # Connect to PostgreSQL and create embeddings
    conn = get_postgres_connection()
    cursor = conn.cursor()

    # Setup LangChain components
    embeddings = OpenAIEmbeddings()  # GPT Embeddings

    @app.route("/", methods=['POST'])
    def talkToGPT():
        print("📥 Anfrage erhalten...")
        prompt = request.json['message']
        prompt = unquote(prompt)
        image_url = request.json['image']  # Image wird im Prompt genutzt

        # Step 1 – Analyse des Raums mit GPT
        llm_vision = ChatOpenAI(model="gpt-4o")  # OpenAI GPT-4o
        message = HumanMessage(
            content=f"You are a professional interior designer. Analyze the following room image ({image_url}) and provide a detailed description of its style."
        )
        response = llm_vision.invoke([message])
        print("📖 Beschreibung des Raumes:")
        print(response.content)
        description_response = response.content

        # Step 2 – Vektor-Suche in der RDS-Datenbank (hier Dummy)
        print("🔍 Suche nach passenden Produkten...")
        vector_search_prompt = f"{prompt} (Raumbeschreibung: {description_response})"

        # Beispiel-Query für PostgreSQL mit Dummy-Daten
        cursor.execute("""
            SELECT id, name, description
            FROM products
            ORDER BY random()
            LIMIT 3;
        """)
        products = cursor.fetchall()

        relevant_docs = ", ".join([f"ID: {p[0]}, Name: {p[1]}, Beschreibung: {p[2]}" for p in products])
        print("📦 Gefundene Produkte:")
        print(relevant_docs)

        # Step 3 – Empfehlung mit GPT
        design_prompt = (
            f"You are an interior designer for Online Boutique. The room style is: {description_response}. "
            f"Here are some relevant products from our catalog: {relevant_docs}. "
            f"The customer asked for: {prompt}. "
            f"Give your recommendations and list the IDs of the top 3 products like this: [ID1], [ID2], [ID3]."
        )
        print("📝 Finaler Prompt:")
        print(design_prompt)

        design_response = llm_vision.invoke(design_prompt)

        return {'content': design_response.content}

    return app


if __name__ == "__main__":
    app = create_app()
    app.run(host='0.0.0.0', port=8080)
