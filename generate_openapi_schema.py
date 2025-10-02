#!/usr/bin/env python3
"""
Generate OpenAPI schema for the Dutch Language Learning API
"""
import json
from app.main import app

def generate_openapi_schema():
    """Generate and save the OpenAPI schema to a JSON file"""
    
    # Get the OpenAPI schema
    openapi_schema = app.openapi()
    
    # Save to file
    with open('api_schema.json', 'w', encoding='utf-8') as f:
        json.dump(openapi_schema, f, indent=2, ensure_ascii=False)
    
    print("OpenAPI schema saved to 'api_schema.json'")
    print(f"Schema contains {len(openapi_schema.get('paths', {}))} endpoints")
    
    # Print summary
    paths = openapi_schema.get('paths', {})
    print("\nAvailable endpoints:")
    for path, methods in paths.items():
        for method, details in methods.items():
            if method.upper() in ['GET', 'POST', 'PUT', 'PATCH', 'DELETE']:
                summary = details.get('summary', 'No description')
                print(f"  {method.upper()} {path} - {summary}")

if __name__ == "__main__":
    generate_openapi_schema()
