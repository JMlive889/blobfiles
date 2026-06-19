# blobfiles

A minimal Flutter web app for clipping, organizing, and sharing content.

## Session summary

This README captures what was built across development sessions (initial setup + shell, auth, navigation, and Google Sign-In groundwork).

### Design system

- **Border radius:** 8px globally (`AppTheme.borderRadius`)
- **Button padding:** elevated 36×22, outlined 28×20
- **Themes:** dark (default) and light, both fully defined

| Token | Dark | Light |
|---|---|---|
| Background | `#0F1117` | `#F8F9FA` |
| Surface | `#1A1D24` | `#FFFFFF` |
| Accent | `#E8E7DC` (cream) | `#5C5A4E` (warm gray) |
| Text primary | `#FFFFFF` | `#1A202C` |
| Text secondary | `#A0A4AD` | `#4A5568` |
| Border | `#2A2E38` | `#E2E8F0` |

Screens use `Theme.of(context).colorScheme` — no hardcoded accent colors.

### Screens & navigation

| Route | Screen | Notes |
|---|---|---|
| `/landing` | Landing | Logo, tagline, Get Started |
| `/login` | Login | Email/password + Google button; back → landing |
| `/library` | Main shell | Bottom nav + AppBar + drawer (default tab: Library) |
| `/library/profile` | Profile Settings | Inside shell — nav + drawer stay visible |
| `/library/templates` | Templates | Inside shell |
| `/library/help` | Help | Inside shell |

**MainShellScreen** (post-login shell):

- **AppBar** — tab title or secondary screen title; back button on secondary screens
- **endDrawer** (hamburger, top right):
  - Profile Settings
  - Templates
  - Help
  - Logout (bottom, divider, error styling)
- **Bottom navigation** (`IndexedStack`, instant tab switch):
  1. **New** — `Icons.public` — discovery placeholder
  2. **Library** — `Icons.video_library` — library placeholder
  3. **Create** — `Icons.add_circle` — create flow placeholder

Secondary screens use `context.go('/library/...')` (not `push`) so the shell stays put and routes do not stack. All shell routes use `NoTransitionPage` for snappy, animation-free navigation.

### Authentication (Supabase)

- Packages: `supabase_flutter`, `google_sign_in`
- Config: `lib/config/supabase_config.dart`, `lib/config/google_config.dart`
- **AuthService** (`lib/services/auth_service.dart`):
  - `signUp`, `signIn`, `signOut`
  - `signInWithGoogle()` — web: Supabase OAuth; native: `google_sign_in` + ID token
  - `initializeGoogleSignIn()`
  - `authStateChanges` stream
- **authProvider** (`lib/auth/auth_provider.dart`):
  - Riverpod `Notifier` — source of truth for auth state
  - Subscribes to Supabase `authStateChanges`; waits for `initialSession`
  - Exposes `AuthState` (`status`, `currentUser`, `isAuthenticated`, `isLoading`)
  - `syncFromClient()` after email sign-in for immediate routing
  - `signOut()` delegates to `AuthService` and updates state reactively
- **AuthService** remains the Supabase/Google API layer; screens and router read state via `authProvider`

**Route protection** (`app_router.dart` + `appRouterProvider`):

| State | Behavior |
|---|---|
| Not logged in + protected route (`/library/*`) | → `/login` |
| Logged in + `/login` | → `/library` |
| Logout | Auth state clears → GoRouter redirect → `/login` |
| Auth init | `authProvider` boots on first read inside `ProviderScope` (no flash) |

Login: sign-in, sign-up, loading states, error banners, back button to landing.

**First user:** use **Create Account** on the login screen.

### Google Sign-In setup (required to enable button)

1. Supabase Dashboard → **Authentication → Providers → Google** → enable
2. Google Cloud → OAuth **Web client ID** (+ secret in Supabase)
3. Supabase → **Authentication → URL Configuration** → add `http://localhost:5173`
4. Run with client ID:
   ```bash
   flutter run -d chrome --web-port 5173 \
     --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_ID.apps.googleusercontent.com
   ```
   Or set `webClientId` in `lib/config/google_config.dart`.

### Project structure

```
lib/
├── auth/
│   ├── auth_provider.dart
│   └── auth_status.dart
├── config/
│   ├── google_config.dart
│   └── supabase_config.dart
├── main.dart
├── router/
│   ├── app_router.dart
│   └── go_router_refresh_stream.dart
├── screens/
│   ├── create_screen.dart
│   ├── help_screen.dart
│   ├── landing_screen.dart
│   ├── library_screen.dart
│   ├── login_screen.dart
│   ├── main_shell_screen.dart
│   ├── new_screen.dart
│   ├── profile_screen.dart
│   └── templates_screen.dart
├── services/
│   └── auth_service.dart
└── theme/
    ├── app_colors.dart
    └── app_theme.dart
web/
├── index.html          # includes passkeys_bundle.js
└── passkeys_bundle.js  # required for supabase_flutter on web
```

## Running the app

**Use your own Terminal app** (not a background agent shell) so hot restart works:

```bash
cd ~/blobfiles && flutter run -d chrome --web-port 5173
```

Or:

```bash
~/blobfiles/dev.sh
```

Opens **http://localhost:5173** in Chrome.

If port 5173 is in use:

```bash
lsof -i :5173 -t | xargs kill -9
```

### Refresh tips

| Action | When to use |
|---|---|
| `flutter run …` or `dev.sh` | After router/auth changes (most reliable) |
| `R` in the flutter terminal | Hot restart |
| `r` | Hot reload — not enough for router/theme changes |
| Cmd+Shift+R in browser | Clear stale cached JS |

### Web requirement

`supabase_flutter` needs the Passkeys Web SDK. It is bundled at `web/passkeys_bundle.js` and loaded in `web/index.html` before `flutter_bootstrap.js`.

## Dependencies

- `flutter` SDK ^3.12.1
- `flutter_riverpod` + `riverpod_annotation` — auth state (`authProvider`) and router wiring
- `go_router` — routing, shell routes, auth redirects
- `supabase_flutter` — email/password + OAuth auth
- `google_sign_in` — native Google Sign-In (web uses Supabase OAuth)

## What's next

- [x] Main shell AppBar + endDrawer menu
- [x] Persistent shell for Profile / Templates / Help
- [x] Auth state + route protection
- [x] Instant navigation (`NoTransitionPage`)
- [x] Google Sign-In groundwork (`signInWithGoogle`)
- [ ] Configure `GOOGLE_WEB_CLIENT_ID` and test Google login end-to-end
- [ ] X OAuth
- [ ] Forgot password flow
- [ ] New tab — discovery feed
- [ ] Create tab — content creation flow
- [ ] Library — real content archive
- [ ] Light/dark mode toggle (light theme is ready)

## Flutter docs

- [Flutter documentation](https://docs.flutter.dev/)
- [Supabase Flutter docs](https://supabase.com/docs/reference/dart/introduction)
- [Supabase Google auth](https://supabase.com/docs/guides/auth/social-login/auth-google?platform=flutter)