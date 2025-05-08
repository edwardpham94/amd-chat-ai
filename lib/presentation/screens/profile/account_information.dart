import 'package:amd_chat_ai/model/user_profile.dart';
import 'package:flutter/material.dart';
import '../widgets/base_screen.dart';
import '../widgets/user_avatar.dart';

class AccountInformationScreen extends StatefulWidget {
  final UserProfile userProfile;

  const AccountInformationScreen({super.key, required this.userProfile});

  @override
  State<AccountInformationScreen> createState() =>
      _AccountInformationScreenState();
}

class _AccountInformationScreenState extends State<AccountInformationScreen> {
  late UserProfile _userProfile;
  final _formKey = GlobalKey<FormState>();

  // Text editing controllers
  late TextEditingController _usernameController;
  late TextEditingController _emailController;

  bool _isLoading = false;
  String? _errorMessage;
  bool _editMode = false;

  @override
  void initState() {
    super.initState();
    _userProfile = widget.userProfile;
    _usernameController = TextEditingController(text: _userProfile.username);
    _emailController = TextEditingController(text: _userProfile.email);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate API call with a delay
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _isLoading = false;
          _editMode = false;

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Account Information',
      showBackButton: true,
      actions: [
        if (!_editMode)
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              setState(() {
                _editMode = true;
              });
            },
          )
        else
          IconButton(icon: const Icon(Icons.check), onPressed: _saveChanges),
      ],
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfilePhoto(),
                      const SizedBox(height: 24),
                      const Text(
                        'User Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D2D5F),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoItem(
                        'User ID',
                        _userProfile.id,
                        isEditable: false,
                      ),
                      const SizedBox(height: 16),
                      _buildTextFormField(
                        'Username',
                        _usernameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Username cannot be empty';
                          }
                          return null;
                        },
                        readOnly: !_editMode,
                      ),
                      const SizedBox(height: 16),
                      _buildTextFormField(
                        'Email',
                        _emailController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email cannot be empty';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                        readOnly: !_editMode,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Account Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D2D5F),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoItem(
                        'User Role',
                        _userProfile.roles.isNotEmpty
                            ? _userProfile.roles.join(', ')
                            : 'No roles assigned',
                        isEditable: false,
                      ),
                      const SizedBox(height: 24),
                      if (_editMode)
                        Padding(
                          padding: const EdgeInsets.only(top: 24.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _editMode = false;
                                      // Reset controllers to original values
                                      _usernameController.text =
                                          _userProfile.username;
                                      _emailController.text =
                                          _userProfile.email;
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _saveChanges,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text('Save Changes'),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildProfilePhoto() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              const UserAvatar(size: 120),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      // Show image picker options
                      _showImagePickerOptions();
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _userProfile.username,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          Text(
            _userProfile.email,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement camera functionality
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement gallery picker
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Remove Photo',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Implement photo removal
                },
              ),
            ],
          ),
    );
  }

  Widget _buildInfoItem(String label, String value, {bool isEditable = true}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (isEditable)
                const Icon(Icons.edit, color: Colors.blue, size: 18),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField(
    String label,
    TextEditingController controller, {
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIcon:
            readOnly ? const Icon(Icons.lock_outline) : const Icon(Icons.edit),
      ),
    );
  }
}
