import httpx
from huggingface_hub import InferenceClient
from openai import AsyncOpenAI
from ..config import settings

class AIService:
    def __init__(self):
        self.default_provider = settings.AI_PROVIDER

    async def chat(self, prompt: str, system: str | None = None, provider: str | None = None, model: str | None = None) -> tuple[str, str, str]:
        provider = (provider or self.default_provider).lower()
        if provider == "openai":
            return await self._chat_openai(prompt, system, model or settings.OPENAI_MODEL)
        elif provider == "hf":
            return await self._chat_hf(prompt, system, model or settings.HF_MODEL)
        else:
            raise ValueError("Unsupported provider: " + provider)

    async def _chat_openai(self, prompt: str, system: str | None, model: str) -> tuple[str, str, str]:
        # Uses official OpenAI client
        client = AsyncOpenAI(
            api_key=settings.OPENAI_API_KEY,
            base_url=settings.OPENAI_API_BASE or None,  # None uses default
        )
        
        # Build messages array
        messages = []
        if system:
            messages.append({"role": "system", "content": system})
        messages.append({"role": "user", "content": prompt})
        
        try:
            completion = await client.chat.completions.create(
                model=model,
                messages=messages,
                temperature=0.2,
                max_tokens=5000,
            )
            
            response_text = completion.choices[0].message.content.strip()
            return response_text, "openai", model
            
        except Exception as e:
            raise Exception(f"OpenAI Client Error: {str(e)}")

    async def _chat_hf(self, prompt: str, system: str | None, model: str) -> tuple[str, str, str]:
        # Uses Hugging Face InferenceClient with Nebius provider
        client = InferenceClient(
            provider="nebius",
            api_key=settings.HF_API_KEY,
        )
        
        # Build messages array
        messages = []
        if system:
            messages.append({"role": "system", "content": system})
        messages.append({"role": "user", "content": prompt})
        
        try:
            completion = client.chat.completions.create(
                model=model,
                messages=messages,
                temperature=0.2,
                max_tokens=5000,
            )
            
            # Check if we got a valid response
            if completion and completion.choices and len(completion.choices) > 0:
                message = completion.choices[0].message
                if message and message.content:
                    response_text = message.content.strip()
                    return response_text, "hf", model
                else:
                    raise Exception("HF API returned empty message content")
            else:
                raise Exception("HF API returned no choices or invalid completion")
            
        except AttributeError as e:
            raise Exception(f"HF API response format error: {str(e)}")
        except Exception as e:
            if "HF InferenceClient Error:" in str(e):
                raise e  # Re-raise our custom errors
            else:
                raise Exception(f"HF InferenceClient Error: {str(e)}")
            
        except Exception as e:
            raise Exception(f"HF InferenceClient Error: {str(e)}")
