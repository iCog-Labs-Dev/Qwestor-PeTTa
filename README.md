# Qwestor-PeTTa


## Architecture

Each query moves through the following pipeline:

```text
User query
  -> Gemini context parser 
  -> appraisal and modulator update 
  -> goal weighting 
  -> dynamic action scoring 
  -> ordered routing guards 
  -> action and response-style selection
  -> state update 
  -> evaluation logs and plots 
```

The available actions are `act_respond`, `act_search`, `act_verify`,
`act_clarify`, `act_decompose`, `act_think`, and `act_synthesize`.

Important files:

- `main/main-loop.metta`: executable multi-query entry point.
- `main/engine-step.metta`: shared single-turn pipeline.
- `operators/appraisal.metta`: context appraisal and modulator updates.
- `operators/decision.metta`: goal weighting and final action selection.
- `operators/routing.metta`: ordered routing guards.
- `main/score_action.py`: dynamic action-relevance scoring bridge.
- `main/context_parser.py`: Gemini context extraction.
- `main/session_logger.py`: evaluation logs, metrics, and plot generation.

## Requirements

- Python 3.10 or newer.
- A working PeTTa installation with a `petta` command or shell function.
- A Gemini API key for the main loop and evaluation tests.

Install the Python dependencies:

```bash
python3 -m venv venv
source venv/bin/activate
python3 -m pip install -r requirements.txt
```
 
## Environment configuration

Create the local environment file:

```bash
cp .env.example .env
```

Then set:

```dotenv
GEMINI_API_KEY=your-api-key-here
GEMINI_MODEL=gemini-3.1-flash-lite
```


## Running Qwestor

Run the main multi-query session from the `main` directory so PeTTa can
resolve the relative imports:

```bash
cd main
petta main-loop.metta
```

The queries used by the evaluation harness are defined in `main/session.py`.

## Tests

Run the offline test suite:

```bash
./run-tests.sh
```

Useful modes:

```bash
./run-tests.sh --clean
./run-tests.sh --verbose
./run-tests.sh --file operators/test/routing-test.metta
```

The evaluation tests make real Gemini API calls and are therefore opt-in:

```bash
./run-tests.sh --eval-smoke  # Session A, 10 turns
./run-tests.sh --eval-full   # Complete evaluation set, 136 turns
./run-tests.sh --eval        # Both evaluation suites
```

## Evaluation output

Evaluation runs write timestamped directories under `logs/` containing:

- `turns.json` and `turns.csv`
- `run_meta.json`
- strict and aggregate metrics under `eval/`
- generated plots under `eval/plots/`