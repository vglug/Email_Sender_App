import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../models/email_group.dart';
import '../data/groups_data.dart';
import '../services/email_service.dart';

class EmailComposeScreen extends StatefulWidget {
  const EmailComposeScreen({super.key});

  @override
  State<EmailComposeScreen> createState() => _EmailComposeScreenState();
}

class _EmailComposeScreenState extends State<EmailComposeScreen> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _emailService = EmailService();
  List<EmailGroup> _groups = [];
  List<EmailGroup> _selectedGroups = [];
  List<PlatformFile> _attachments = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  void _loadGroups() {
    _groups = groupsData.map((group) => EmailGroup.fromJson(group)).toList();
  }

  bool _isGroupSelected(EmailGroup group) {
    return _selectedGroups.contains(group);
  }

  void _toggleGroup(EmailGroup group) {
    setState(() {
      if (_isGroupSelected(group)) {
        _selectedGroups.remove(group);
      } else {
        _selectedGroups.add(group);
      }
    });
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null) {
        setState(() {
          _attachments.addAll(result.files);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking files: $e')),
      );
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Widget _buildAttachmentChip(PlatformFile file, int index) {
    String fileSize = '${(file.size / 1024).toStringAsFixed(1)} KB';
    
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Chip(
        avatar: Icon(_getFileIcon(file.extension ?? '')),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(file.name),
            const SizedBox(width: 4),
            Text(
              fileSize,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        deleteIcon: const Icon(Icons.close, size: 18),
        onDeleted: () => _removeAttachment(index),
      ),
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      case 'mp4':
      case 'mov':
        return Icons.video_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<void> _sendEmail() async {
    if (_selectedGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one group')),
      );
      return;
    }

    if (_subjectController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      List<String> attachmentPaths = _attachments.map((file) => file.path!).toList();
      
      // Get all unique email addresses from selected groups
      Set<String> allEmails = {};
      for (var group in _selectedGroups) {
        allEmails.addAll(group.emails);
      }
      
      await _emailService.sendEmail(
        subject: _subjectController.text,
        body: _messageController.text,
        recipients: allEmails.toList(),
        attachments: attachmentPaths,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email sent successfully!')),
      );
      
      // Clear form after successful send
      _clearForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send email: $e')),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _clearForm() {
    setState(() {
      _subjectController.clear();
      _messageController.clear();
      _attachments.clear();
      _selectedGroups.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Compose Email'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            actions: [
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _isSending ? null : _sendEmail,
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'To:',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          ..._selectedGroups.map((group) => Chip(
                            label: Text(group.name),
                            onDeleted: () => _toggleGroup(group),
                          )),
                          StatefulBuilder(
                            builder: (context, setStatePopup) => PopupMenuButton<EmailGroup>(
                              child: const Chip(
                                label: Text('Add Group'),
                                avatar: Icon(Icons.add),
                              ),
                              itemBuilder: (context) => _groups
                                  .map((group) => PopupMenuItem(
                                        value: group,
                                        enabled: false,
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              value: _isGroupSelected(group),
                                              onChanged: (_) {
                                                _toggleGroup(group);
                                                setStatePopup(() {}); // Rebuild popup
                                              },
                                            ),
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  _toggleGroup(group);
                                                  setStatePopup(() {}); // Rebuild popup
                                                },
                                                child: Text(group.name),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                              onSelected: null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.subject),
                  ),
                ),
                const SizedBox(height: 16),
                if (_attachments.isNotEmpty) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _attachments
                          .asMap()
                          .entries
                          .map((entry) => _buildAttachmentChip(entry.value, entry.key))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      hintText: 'Compose email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomAppBar(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _isSending ? null : _pickFiles,
                  tooltip: 'Attach files',
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text('Discard'),
                  onPressed: _isSending ? null : _clearForm,
                ),
              ],
            ),
          ),
        ),
        if (_isSending)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }
} 