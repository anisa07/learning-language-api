import httpx
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
        base = settings.OPENAI_API_BASE or "https://api.openai.com/v1"
        url = f"{base}/chat/completions"
        headers = {"Authorization": f"Bearer {settings.OPENAI_API_KEY}"}
        payload = {
            "model": model,
            "messages": ([{"role": "system", "content": system}] if system else []) +
                        [{"role": "user", "content": prompt}],
            "temperature": 0.2,
        }
        async with httpx.AsyncClient(timeout=60) as client:
            r = await client.post(url, headers=headers, json=payload)
            r.raise_for_status()
            data = r.json()
            text = data["choices"][0]["message"]["content"].strip()
            return text, "openai", model

    async def _chat_hf(self, prompt: str, system: str | None, model: str) -> tuple[str, str, str]:
        # Uses text-generation (instruct) endpoint
        url = f"https://api-inference.huggingface.co/models/{model}"
        headers = {"Authorization": f"Bearer {settings.HF_API_KEY}"}
        system_part = system + '\n' if system else ''
        full_prompt = f"<s>[INST] {system_part}{prompt} [/INST]"
        payload = {"inputs": full_prompt, "parameters": {"temperature": 0.2, "max_new_tokens": 512}}
        async with httpx.AsyncClient(timeout=120) as client:
            r = await client.post(url, headers=headers, json=payload)
            r.raise_for_status()
            data = r.json()
            # HF responses can be a list or dict depending on model/router
            if isinstance(data, list) and data and "generated_text" in data[0]:
                out = data[0]["generated_text"]
                # strip the prompt prefix if returned
                return out.replace(full_prompt, "").strip(), "hf", model
            elif isinstance(data, dict) and "generated_text" in data:
                return data["generated_text"].strip(), "hf", model
            else:
                # fallback
                return str(data), "hf", model
