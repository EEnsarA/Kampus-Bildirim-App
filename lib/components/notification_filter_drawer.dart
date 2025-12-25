import 'package:flutter/material.dart';
import 'package:kampus_bildirim/models/app_user.dart';
import 'package:kampus_bildirim/models/app_notification.dart';

class NotificationFilterDrawer extends StatefulWidget {
  final AppUser user;

  // Başlangıç değerlerini dışarıdan alıyoruz ki seçili olanlar kalsın
  final List<NotificationType> initialSelectedTypes;
  final bool initialOnlyOpen;
  final bool initialOnlyFollowed;
  final bool initialOnlyMyDepartment;

  // Filtreler uygulandığında bu fonksiyon çalışacak ve verileri Home'a geri yollayacak
  final Function(
    List<NotificationType> selectedTypes,
    bool onlyOpen,
    bool onlyFollowed,
    bool onlyMyDepartment,
  )
  onApply;

  const NotificationFilterDrawer({
    super.key,
    required this.user,
    required this.initialSelectedTypes,
    required this.initialOnlyOpen,
    required this.initialOnlyFollowed,
    required this.initialOnlyMyDepartment,
    required this.onApply,
  });

  @override
  State<NotificationFilterDrawer> createState() =>
      _NotificationFilterDrawerState();
}

class _NotificationFilterDrawerState extends State<NotificationFilterDrawer> {
  // Local state (Sadece drawer açıkken geçerli olan geçici durum)
  late List<NotificationType> _selectedTypes;
  late bool _onlyOpen;
  late bool _onlyFollowed;
  late bool _onlyMyDepartment;

  @override
  void initState() {
    super.initState();
    // Başlangıç değerlerini alıp yerel değişkenlere atıyoruz
    _selectedTypes = List.from(widget.initialSelectedTypes);
    _onlyOpen = widget.initialOnlyOpen;
    _onlyFollowed = widget.initialOnlyFollowed;
    _onlyMyDepartment = widget.initialOnlyMyDepartment;
  }

  // --- YARDIMCI FONKSİYONLAR (Buraya taşıdık) ---
  String _getLabelForType(NotificationType type) {
    switch (type) {
      case NotificationType.emergency:
        return "ACİL DURUM";
      case NotificationType.lostFound:
        return "Kayıp / Buluntu";
      case NotificationType.event:
        return "Etkinlik";
      case NotificationType.general:
        return "Genel Duyuru";
      case NotificationType.failure:
        return "Arıza";
      case NotificationType.environment:
        return "Çevresel";
    }
  }

  Color _getColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.emergency:
        return Colors.red;
      case NotificationType.lostFound:
        return Colors.blue;
      case NotificationType.environment:
        return Colors.green;
      case NotificationType.general:
        return Colors.grey.shade700;
      case NotificationType.failure:
        return Colors.orange;
      case NotificationType.event:
        return Colors.deepPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      child: SafeArea(
        child: Column(
          children: [
            // --- BAŞLIK ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Filtrele",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedTypes.clear();
                        _onlyOpen = false;
                        _onlyFollowed = false;
                        _onlyMyDepartment = false;
                      });
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text("Sıfırla"),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // --- İÇERİK ---
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  const Text(
                    "Bildirim Türü",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children:
                        NotificationType.values.map((type) {
                          final isSelected = _selectedTypes.contains(type);
                          final label = _getLabelForType(type);
                          final color = _getColorForType(type);

                          return FilterChip(
                            label: Text(label),
                            selected: isSelected,
                            showCheckmark: false,
                            selectedColor: color.withValues(alpha: 0.2),
                            checkmarkColor: color,
                            labelStyle: TextStyle(
                              color: isSelected ? color : Colors.black87,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                            side:
                                isSelected
                                    ? BorderSide(color: color)
                                    : const BorderSide(color: Colors.grey),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  _selectedTypes.add(type);
                                } else {
                                  _selectedTypes.remove(type);
                                }
                              });
                            },
                          );
                        }).toList(),
                  ),

                  const SizedBox(height: 24),
                  const Divider(),

                  const Text(
                    "Durum ve Tercihler",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Sadece Açık Talepler"),
                    subtitle: const Text("Çözülenleri gizle"),
                    value: _onlyOpen,
                    activeColor: Colors.green,
                    onChanged: (val) => setState(() => _onlyOpen = val),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Takip Ettiklerim"),
                    subtitle: const Text("Favorilere eklediklerim"),
                    value: _onlyFollowed,
                    activeColor: Colors.redAccent,
                    secondary: Icon(
                      _onlyFollowed ? Icons.favorite : Icons.favorite_border,
                      color: _onlyFollowed ? Colors.red : null,
                    ),
                    onChanged: (val) => setState(() => _onlyFollowed = val),
                  ),

                  // Admin Kontrolü
                  if (widget.user.role == 'admin') ...[
                    const Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Kendi Birimim"),
                      subtitle: Text("${widget.user.department} bildirimleri"),
                      value: _onlyMyDepartment,
                      onChanged:
                          (val) => setState(() => _onlyMyDepartment = val),
                    ),
                  ],
                ],
              ),
            ),

            // --- UYGULA BUTONU ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // Callback ile değerleri Home'a gönderiyoruz
                    widget.onApply(
                      _selectedTypes,
                      _onlyOpen,
                      _onlyFollowed,
                      _onlyMyDepartment,
                    );
                    Navigator.pop(context); // Drawer'ı kapat
                  },
                  child: const Text(
                    "Sonuçları Göster",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
