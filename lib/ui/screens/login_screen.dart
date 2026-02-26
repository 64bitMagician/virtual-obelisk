import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository.dart';

/// The Login Screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Our tool of communicating with the Authentication SDK of Firebase
  final AuthRepository _authRepo = AuthRepository();

 // Text controllers for the two authentication text fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // _isLoading is indicating the time period from when we process and check the authentication credentials with
  // Firebase, up until a conclusion is reached (authentication succesful, or error)
  // So in simple terms, _isLoading is set to true once we click on the authenticate button,
  // up until we reach a conclusion with the authentication. Then the _isLoading is set to false again.
  bool _isLoading = false;

  // bool if the user is currently logging in (signing in), or signing up
  bool _isLogin = true;

  // custom dispose method, for when the object is removed from the tree
  // the object will be removed as default
  // but we also make sure that the two instanced controllers are disposed too
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    // This method gets called whenever the authenticate button gets pressed

    // In case the user hasn't written anything within the text fields
    // we display a message to him...
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    // ?we rebuild the screen while indicating that we are loading
    setState(() => _isLoading = true);

    // we attempt to log in/sign in
    try {
      if (_isLogin) { // If the user is entering data for logging in...
        // we call our authentication repository to check if the provided authentication creadentials
        // match with any existing ones on Authentication SDK Firebase
        await _authRepo.signIn(
          email: _emailController.text.trim(), // the text from email text field
          password: _passwordController.text.trim(), // the text from password text field
        );
      } else { // If the user is entering data for signing up ...
        await _authRepo.signUp(
          // we call our authentication repository to check if the provided authentication creadentials
          // are valid for creating a new account. If everything is valid, an account for the user
          // will be created
          email: _emailController.text.trim(), // the text from email text field
          password: _passwordController.text.trim(), // the text from password text field
        );
      }

    } catch (e) {
      if (mounted) { // if the LoginScreen and it's state is still within the tree, we can use it's context
        // to reach the ScaffoldMessenger class

        // We want to represent the error on web, using a SnackBar...
        final String message = e.toString().replaceAll("Exception: ", "");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally { // finally always runs, whatever happens in try-catch
      // Only if we are still on the LoginScreen()
      // we indicate that we are no longer loading
      // the autnentication process has finished (with or without error)
      // so we rebuild the screen anyway (if we had not already passed to the realm of the platform)
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // The visual part
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder( // responsive for laptopScreen/Phone
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) { // laptop mode
            return Row(
              children: [
                // Left Side: The Art Image and logo and whatever...
                Expanded(
                  flex: 1, // Takes 50% width
                  child: Container(
                    color: Colors.black,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network( // the image
                          'https://picsum.photos/id/1015/1000/1000',
                          // As small as possible while still covering the entire target box.
                          fit: BoxFit.cover,
                          color: Colors.black.withOpacity(0.6), // Darken it slightly
                          colorBlendMode: BlendMode.darken,
                        ),
                        const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.brush, size: 80, color: Colors.white), // Logo
                              SizedBox(height: 20),
                              Text( // App Name
                                "LibArt",
                                style: TextStyle( // styling of app name text
                                  fontFamily: 'serif',
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text( // some more suggestive text and it's style
                                "Where creativity connects.",
                                style: TextStyle(color: Colors.white70, fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Right Side: The Authentification Form
                Expanded(
                  flex: 1, // Takes 50% width
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      padding: const EdgeInsets.all(32),
                      child: _buildForm(), // this will return the Form Widget
                    ),
                  ),
                ),
              ],
            );
          } else { // phone mode
            // We no longer have a left side for art and right side for form, just the form
            return Center(
              child: SingleChildScrollView( // can be scrolled
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // make everythin allign on center vertically
                    children: [
                      //logo
                      const Icon(Icons.brush, size: 60, color: Colors.deepPurple),
                      const SizedBox(height: 16),
                      Text( // App Name + style
                        "LibArt",
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'serif',
                        ),
                      ),
                      const SizedBox(height: 48),
                      // The method that returns the Form Widget
                      _buildForm(),
                    ],
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  // This method returns the Form Widget
  // This includes text fields, authentication buttons, switch to sign up or in...
  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min, // minimize the ammount of free space
      crossAxisAlignment: CrossAxisAlignment.stretch, // the widgets will resize horizontally
      children: [
        Text( // text defers on wether you are logging in / signing up
          _isLogin ? "Welcome Back" : "Join the Community",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // email text form field, we pas the email controller
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: "Email", // what is shown when text field is empty
            prefixIcon: Icon(Icons.email_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: "Password", // what is shown when text field is empty
            prefixIcon: Icon(Icons.lock_outline),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),

        ElevatedButton(
          // if we are already loading (process and check authentication credentials with Firebase)
          // we get null, meaning nothing will happen (we don't to reexecute authentication if it ongoing)
          // otherwise, we can call the method to try authentication with the given credentials in the
          // text fields
          onPressed: _isLoading ? null : _handleAuth,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
          // If we are loading, we display a circular process indicator, inplying that authentication is in the works
          // if we are not loading, we are displaying the authentication text, to suggest to the user that he can
          // press the button whenever he wants
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(_isLogin ? "Login" : "Create Account"), // displays according to login state
        ),
        const SizedBox(height: 16),
        // A text button that switches from login state to sign up state.
        // calls set state to retrigger the building of the screen...
        TextButton(
          onPressed: () {
            setState(() {
              _isLogin = !_isLogin;
            });
          },
          child: Text(
            _isLogin
                ? "Don't have an account? Sign Up"
                : "Already have an account? Login",
          ),
        ),
      ],
    );
  }
}