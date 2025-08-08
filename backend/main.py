"""
Main FastAPI application for the Criminal Justice AI Suite.

This server provides API endpoints for all six personas in the project:
1. Investigator: Matches biometric evidence to a suspect database.
2. Pre-Trial Analyst: Calculates a pre-trial risk score for a defendant.
3. Sentencing Advisor: Recommends a sentence based on historical data.
4. Corrections Officer: Monitors an offender for GPS and curfew violations.
5. Auditor: Runs an interactive bias simulation.
6. System Architect: Manages digital case files.
"""
import uvicorn
import datetime
import pandas as pd
import numpy as np
from fastapi import FastAPI, status
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
from typing import List, Dict, Any

# ===================================================================
# FastAPI App Initialization and CORS Configuration
# ===================================================================

app = FastAPI(title="Criminal Justice AI Suite API")

# CORS (Cross-Origin Resource Sharing) middleware is essential for
# allowing the Flutter app (especially in a web browser) to communicate with this backend.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins for development purposes.
    allow_credentials=True,
    allow_methods=["*"],  # Allows all HTTP methods (GET, POST, PUT, etc.).
    allow_headers=["*"],  # Allows all headers.
)

# ===================================================================
# Pydantic Models (Input Data Validation for API Endpoints)
# ===================================================================

class HashInput(BaseModel):
    crime_scene_hash: str

class DefendantProfileInput(BaseModel):
    prior_offenses: int
    age_at_first_arrest: int
    has_stable_employment: bool

class SentencingInput(BaseModel):
    crime_type: str
    severity_score: int

class GpsInput(BaseModel):
    current_x: float
    current_y: float
    current_hour: int

class AuditInput(BaseModel):
    bias_multiplier: float = 2.5

class CaseCreateInput(BaseModel):
    case_id: str
    defendant_name: str

class EvidenceInput(BaseModel):
    evidence_item: str

class StatusInput(BaseModel):
    new_status: str

# ===================================================================
# Person 1: Investigator
# ===================================================================
suspect_database = {
    'A1B2-C3D4-E5F6': { 'name': 'John Doe', 'id': 'SUS101', 'fingerprint_details': 'right thumb, whorl pattern', 'last_known_location': 'East City' },
    'F7E8-D9C0-B1A2': { 'name': 'Jane Smith', 'id': 'SUS102', 'fingerprint_details': 'left index, loop pattern', 'last_known_location': 'Northwood' },
    '1234-5678-ABCD': { 'name': 'Peter Jones', 'id': 'SUS103', 'fingerprint_details': 'right index, arch pattern', 'last_known_location': 'Southville' }
}

@app.get("/investigator/database", tags=["Person 1: Investigator"])
def api_get_suspect_database():
    suspect_list = [details for details in suspect_database.values()]
    return {"status": "success", "data": suspect_list}

@app.post("/investigator/find_match", tags=["Person 1: Investigator"])
def api_find_match(data: HashInput):
    match = suspect_database.get(data.crime_scene_hash)
    if match:
        return {"status": "success", "message": "Match Found!", "data": match}
    return {"status": "not_found", "message": "No match found in the database."}

# ===================================================================
# Person 2: Pre-Trial Analyst
# ===================================================================
@app.post("/pretrial/calculate_risk", tags=["Person 2: Pre-Trial Analyst"])
def api_calculate_risk(data: DefendantProfileInput):
    age_factor = 2 if data.age_at_first_arrest < 21 else 0
    employment_factor = 2 if not data.has_stable_employment else 0
    risk_score = (data.prior_offenses * 3) + (age_factor * 2) + (employment_factor * 1)
    return {"status": "success", "data": {"risk_score": risk_score}}

# ===================================================================
# Person 3: Sentencing Advisor (Nyay Sarthi)
# ===================================================================
class NyaySarthiTool:
    def __init__(self, dataset: List[Dict[str, Any]]):
        self.dataset = dataset
    def recommend_sentence(self, crime_type: str, severity_score: int) -> Dict[str, Any]:
        def get_stats(cases):
            if not cases: return None
            sentences = [c['sentence_given_months'] for c in cases]
            return {"recommendation_months": round(sum(sentences) / len(sentences), 1), "min_sentence": min(sentences), "max_sentence": max(sentences), "case_count": len(cases)}
        matching_cases = [c for c in self.dataset if c['crime_type'] == crime_type and c['severity_score'] == severity_score]
        if matching_cases:
            stats = get_stats(matching_cases)
            return {"status": "Success", "data": stats, "basis": f"Direct match from {stats['case_count']} historical case(s)."}
        adjacent = [s for s in [severity_score - 1, severity_score + 1] if 1 <= s <= 5]
        similar_cases = [c for c in self.dataset if c['crime_type'] == crime_type and c['severity_score'] in adjacent]
        if similar_cases:
            stats = get_stats(similar_cases)
            return {"status": "Success (Estimated)", "data": stats, "basis": f"Estimate based on {stats['case_count']} case(s) with similar severity."}
        return {"status": "Failed", "data": None, "basis": "No historical data found for this crime type."}

historical_data = [{'case_id': 'HN001', 'crime_type': 'Theft', 'severity_score': 2, 'sentence_given_months': 3}, {'case_id': 'HN002', 'crime_type': 'Assault', 'severity_score': 3, 'sentence_given_months': 12}, {'case_id': 'HN003', 'crime_type': 'Burglary', 'severity_score': 4, 'sentence_given_months': 24}, {'case_id': 'HN004', 'crime_type': 'Fraud', 'severity_score': 5, 'sentence_given_months': 60}, {'case_id': 'HN005', 'crime_type': 'Theft', 'severity_score': 2, 'sentence_given_months': 4}, {'case_id': 'HN006', 'crime_type': 'Vandalism', 'severity_score': 1, 'sentence_given_months': 1}, {'case_id': 'HN007', 'crime_type': 'Burglary', 'severity_score': 4, 'sentence_given_months': 30}, {'case_id': 'HN008', 'crime_type': 'Assault', 'severity_score': 4, 'sentence_given_months': 18}, {'case_id': 'HN009', 'crime_type': 'Theft', 'severity_score': 3, 'sentence_given_months': 6}, {'case_id': 'HN010', 'crime_type': 'Burglary', 'severity_score': 4, 'sentence_given_months': 28}]
nyay_sarthi_instance = NyaySarthiTool(dataset=historical_data)

@app.post("/sentencing/recommend", tags=["Person 3: Sentencing Advisor"])
def api_recommend_sentence(data: SentencingInput):
    return nyay_sarthi_instance.recommend_sentence(crime_type=data.crime_type, severity_score=data.severity_score)

# ===================================================================
# Person 4: Corrections Officer
# ===================================================================
SAFE_ZONE_X_MIN, SAFE_ZONE_X_MAX = 10.0, 90.0
SAFE_ZONE_Y_MIN, SAFE_ZONE_Y_MAX = 10.0, 90.0
CURFEW_START_HOUR, CURFEW_END_HOUR = 22, 6

@app.post("/corrections/check_violation", tags=["Person 4: Corrections Officer"])
def api_check_violation(data: GpsInput):
    violations = []
    if not (SAFE_ZONE_X_MIN <= data.current_x <= SAFE_ZONE_X_MAX and SAFE_ZONE_Y_MIN <= data.current_y <= SAFE_ZONE_Y_MAX):
        violations.append("Location Violation: Offender is outside the designated safe zone.")
    if data.current_hour >= CURFEW_START_HOUR or data.current_hour < CURFEW_END_HOUR:
        violations.append("Curfew Violation: Monitored during curfew hours.")
    if not violations:
        violations.append("Status: Compliant")
    return {"status": "success", "data": {"violations": violations}}

# ===================================================================
# Person 5: Auditor
# ===================================================================
@app.post("/auditor/run_simulation", tags=["Person 5: Auditor"])
def api_run_audit_simulation(data: AuditInput):
    np.random.seed()
    df = pd.DataFrame({'race': ['Group A', 'Group B'] * 10, 'prior_offenses': np.random.randint(1, 11, 20)})
    df['risk_score'] = df.apply(lambda r: r['prior_offenses'] * 1.5 if r['race'] == 'Group A' else r['prior_offenses'] * data.bias_multiplier, axis=1)
    avg_scores = df.groupby('race')['risk_score'].mean().round(2)
    score_a, score_b = avg_scores.get('Group A', 0), avg_scores.get('Group B', 0)
    disparity = round(score_b / score_a, 2) if score_a > 0 else 0
    return {"status": "Success", "data": {"Group A": score_a, "Group B": score_b, "disparity_factor": disparity}, "message": "Audit simulation complete."}

# ===================================================================
# Person 6: System Architect
# ===================================================================
case_files_db: Dict[str, 'CriminalCase'] = {}

class CriminalCase:
    def __init__(self, case_id: str, defendant_name: str):
        self.case_id = case_id
        self.defendant_name = defendant_name
        self.evidence_log: List[Dict[str, str]] = []
        self.case_status: str = "Investigation"
    def add_evidence(self, evidence_item: str):
        self.evidence_log.append({"evidence_item": evidence_item, "timestamp": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")})
    def update_status(self, new_status: str):
        self.case_status = new_status
    def to_dict(self): return self.__dict__

@app.get("/cases", tags=["Person 6: System Architect"])
def api_get_all_cases():
    return {"status": "success", "data": [case.to_dict() for case in case_files_db.values()]}

@app.post("/case/create", status_code=status.HTTP_201_CREATED, tags=["Person 6: System Architect"])
def api_create_case(data: CaseCreateInput):
    if data.case_id in case_files_db:
        return {"status": "error", "message": "Case ID already exists."}
    new_case = CriminalCase(case_id=data.case_id, defendant_name=data.defendant_name)
    case_files_db[data.case_id] = new_case
    return {"status": "success", "data": new_case.to_dict()}

@app.get("/case/{case_id}", tags=["Person 6: System Architect"])
def api_get_case(case_id: str):
    case = case_files_db.get(case_id)
    if case:
        return {"status": "success", "data": case.to_dict()}
    return {"status": "not_found", "message": "Case not found."}

@app.put("/case/{case_id}/add_evidence", tags=["Person 6: System Architect"])
def api_add_evidence(case_id: str, data: EvidenceInput):
    case = case_files_db.get(case_id)
    if case:
        case.add_evidence(data.evidence_item)
        return {"status": "success", "data": case.to_dict()}
    return {"status": "not_found", "message": "Case not found."}

@app.put("/case/{case_id}/update_status", tags=["Person 6: System Architect"])
def api_update_status(case_id: str, data: StatusInput):
    case = case_files_db.get(case_id)
    if case:
        case.update_status(data.new_status)
        return {"status": "success", "data": case.to_dict()}
    return {"status": "not_found", "message": "Case not found."}

# ===================================================================
# Main Execution Block to Run the Server
# ===================================================================
if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8001, reload=True)