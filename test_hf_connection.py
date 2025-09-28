#!/usr/bin/env python3

import asyncio
import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.services.ai import AIService

async def test_openai():
    print("🔧 Testing OpenAI...")
    ai = AIService()
    
    try:
        response, provider, model = await ai.chat(
            prompt="Tell me a short joke.",
            system="You are a helpful assistant.",
            provider="openai",
            model="gpt-4o-mini"
        )
        
        print(f"✅ OpenAI Success!")
        print(f"Provider: {provider}")
        print(f"Model: {model}")
        print(f"Response: {response}")
        
    except Exception as e:
        print(f"❌ OpenAI Error: {e}")

async def test_hf():
    print("\n🔧 Testing Hugging Face...")
    ai = AIService()
    
    try:
        response, provider, model = await ai.chat(
            prompt="Hello, how are you?",
            system="You are a helpful assistant.",
            provider="hf",
            model="openai/gpt-oss-20b"
        )
        
        print(f"✅ HF Success!")
        print(f"Provider: {provider}")
        print(f"Model: {model}")
        print(f"Response: {response}")
        
    except Exception as e:
        print(f"❌ HF Error: {e}")

async def main():
    await test_openai()
    await test_hf()

if __name__ == "__main__":
    asyncio.run(main())