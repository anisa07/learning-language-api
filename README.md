# Python Playground

A simple Python project template for learning and experimentation.

## Project Structure

```
python-playground/
├── .github/
│   └── copilot-instructions.md
├── .vscode/
│   └── settings.json
├── main.py                 # Main Python script
├── requirements.txt        # Project dependencies
├── README.md              # This file
└── .gitignore             # Git ignore rules
```

## Getting Started

1. **Prerequisites**

   - Python 3.7 or higher
   - VS Code with Python extension

2. **Installation (After Cloning)**

   ```bash
   # 1. Clone the repository
   git clone <repository-url>
   cd python-playground

   # 2. Create a virtual environment
   python -m venv .venv
   # Note: Use 'python3' instead of 'python' if needed on your system

   # 3. Activate the virtual environment
   # On macOS/Linux:
   source .venv/bin/activate
   # On Windows:
   # .venv\Scripts\activate

   # 4. Install dependencies
   pip install -r requirements.txt

   # 5. Verify installation
   python main.py
   ```

   **You should see** `(.venv)` in your terminal prompt when the virtual environment is activated.

## Development without docker

- **Activate environment**: `source .venv/bin/activate` (run this each time you open a new terminal)
- **Deactivate environment**: `deactivate` (when you're done working)
- **Run script**: `python main.py` (with virtual environment activated)
- **VS Code**: Use the integrated terminal and debugger for development

## Development with docker (you don't need to activate the virtual environment)

### Run Development

```bash
python docker_helper.py up
```

### Stop Development

```bash
python docker_helper.py down
```

## Production

```bash
python docker_helper.py prod
```

## Next Steps

- Add more Python modules as needed
- Configure debugging in VS Code
- Set up testing with pytest
- Add type hints and linting configuration
