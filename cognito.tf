# ── Cognito User Pool ──────────────────────────────────────────────────────
# Central identity store for all EHR users. MFA is mandatory to align with
# HIPAA Technical Safeguard requirements for access control.
resource "aws_cognito_user_pool" "ehr" {
  name = "${var.project_name}-user-pool"

  # "ON" enforces MFA for every user; "OPTIONAL" lets users opt in
  mfa_configuration = "ON"

  software_token_mfa_configuration {
    enabled = true   # TOTP via any authenticator app (e.g. Google Authenticator)
  }

  # Strong password policy
  password_policy {
    minimum_length                   = 12
    require_uppercase                = true
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 1
  }

  # Cognito sends a verification code to the email before activating an account
  auto_verified_attributes = ["email"]

  # Self-service account recovery uses the verified email address
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  tags = { Name = "${var.project_name}-user-pool" }
}

# ── App Client ─────────────────────────────────────────────────────────────
# The app client is the credential set used by the EHR front-end to talk to
# the User Pool. SRP-based auth avoids sending plaintext passwords over the wire.
resource "aws_cognito_user_pool_client" "ehr" {
  name         = "${var.project_name}-app-client"
  user_pool_id = aws_cognito_user_pool.ehr.id

  generate_secret = false   # public client (SPA / mobile); set true for server-side apps

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",       # Secure Remote Password — no plaintext password
    "ALLOW_REFRESH_TOKEN_AUTH"   # allows silent token renewal
  ]
}
