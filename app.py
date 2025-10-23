from nicegui import ui, app
from typing import Any
from cachetools import TTLCache
from msal import ConfidentialClientApplication
from sqlmodel import Session
from fastapi.responses import RedirectResponse
from azure.identity import DefaultAzureCredential
import os
from dotenv import load_dotenv

# --- Load environment ---
load_dotenv()

# --- Azure Authentication / Key Vault Setup ---
credential = DefaultAzureCredential()

CLIENT_ID = os.getenv("CLIENT_ID")
CLIENT_SECRET = os.getenv("CLIENT_SECRET")
TENANT_NAME = os.getenv("TENANT_NAME")
AUTHORITY = f"https://login.microsoftonline.com/{TENANT_NAME}"
SCOPE = ["User.Read"]
REDIRECT_PATH = "/.auth/login/aad/callback"
LOGOUT_URL = f"{AUTHORITY}/oauth2/v2.0/logout"

# --- MSAL App Setup ---
msal_app = ConfidentialClientApplication(
    CLIENT_ID,
    authority=AUTHORITY,
    client_credential=CLIENT_SECRET,
)

# --- Cache Stores ---
AUTH_FLOW_STATES: TTLCache[str, dict[str, Any]] = TTLCache(maxsize=256, ttl=5 * 60)
USER_DATA: TTLCache[str, dict[str, Any]] = TTLCache(maxsize=256, ttl=10 * 60 * 60)

# --- Require Login Decorator ---
def require_login() -> dict[str, Any] | None:
    browser_id = app.storage.browser.get("id")
    user = USER_DATA.get(browser_id)
    if not user:
        ui.navigate.to("/login")
        return None
    return user

# --- Login Pages Registration ---
def register_login_pages():
    @ui.page("/login")
    def login_page():
        ui.label("Please authenticate")
        ui.button("Login with Microsoft", on_click=start_login)

    @ui.page(REDIRECT_PATH)
    def auth_redirect():
        # Placeholder - real handler processes token here
        ui.notify("Login successful")
        ui.navigate.to("/home")

def start_login():
    flow = msal_app.initiate_auth_code_flow(
        SCOPE,
        redirect_uri=f"{os.getenv('BASE_URL')}{REDIRECT_PATH}",
    )
    state = flow["state"]
    AUTH_FLOW_STATES[state] = flow
    #return RedirectResponse(flow["auth_uri"])
    ui.navigate.to("/home")

# Register authentication routes
register_login_pages()

# --- Example Page: Home Dashboard ---
@ui.page("/")
def index():
    user = require_login()
    if not user:
        return
    ui.label(f"Welcome {user.get('name', 'User')}")
    ui.button("Go to dashboard", on_click=lambda: ui.navigate.to("/home"))

@ui.page("/home")
def home_page():
    user = require_login()
    if not user:
        return
    ui.label("This is the dashboard")
    ui.button("Logout", on_click=lambda: ui.open(LOGOUT_URL))

# --- Example Database Session Setup ---
def get_engine():
    # Normally return engine from SQLModel
    pass

engine = get_engine()

# --- Example Protected Page Using Database ---
@ui.page("/protected")
def protected_route():
    user = require_login()
    if not user:
        return
    with Session(engine) as session:
        ui.label("Secure data loaded here...")

# --- Run App ---
if __name__ in {"__main__", "__mp_main__"}:
    ui.run(
        title="Core App Template",
        host="0.0.0.0",
        port=8080,
        storage_secret=os.getenv("STORAGE_SECRET"),
    )