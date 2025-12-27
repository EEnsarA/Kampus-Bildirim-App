import 'package:flutter/material.dart';
import 'package:kampus_bildirim/components/status_tag.dart';
import 'package:kampus_bildirim/models/app_user.dart';

class ProfileInfoCard extends StatelessWidget {
  final AppUser user;
  final VoidCallback? onEditImage;
  final VoidCallback? onEditName;
  const ProfileInfoCard({
    super.key,
    required this.user,
    required this.onEditImage,
    this.onEditName,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 184, 180, 180),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: primaryColor.withValues(alpha: 0.1),
                backgroundImage:
                    user.avatarUrl != null
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                child:
                    user.avatarUrl == null
                        ? Icon(
                          Icons.account_circle_rounded,
                          size: 64,
                          color: Theme.of(context).colorScheme.secondary,
                        )
                        : null,
              ),

              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onEditImage,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 20),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (onEditName != null)
                      GestureDetector(
                        onTap: onEditName,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  children: [
                    if (user.role != "user")
                      StatusTag(text: user.role, color: Colors.red),
                    if (user.department.isNotEmpty)
                      StatusTag(
                        text: user.department,
                        color: Color.fromARGB(255, 223, 182, 125),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
