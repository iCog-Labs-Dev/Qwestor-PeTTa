from pathlib import Path
import importlib.util


def load_queries():
    sessions_file = Path(__file__).parent / "session.py"

    spec = importlib.util.spec_from_file_location("_sessions", sessions_file)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)

    sessions = getattr(module, "SESSIONS", [])

    def to_metta_list(atoms):
        result = "()"
        for atom in reversed(atoms):
            result = f"(Cons {atom} {result})"
        return result

    result = []
    for session in sessions:
        query_atoms = []
        for q in session["queries"]:
            escaped = q.replace('"', '\\"')
            query_atoms.append(f'"{escaped}"')
        result.append(to_metta_list(query_atoms))

    return to_metta_list(result)