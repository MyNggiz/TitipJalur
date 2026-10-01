import 'package:flutter/material.dart';

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badgeCount;

  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount,
  });
}

class InteractiveBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavItem> items;

  const InteractiveBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  State<InteractiveBottomNav> createState() => _InteractiveBottomNavState();
}

class _InteractiveBottomNavState extends State<InteractiveBottomNav> {
  static const Color _primaryEmerald = Color(0xFF059669);
  static const Color _inactiveSlate = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);

  int? _hoveredIndex;
  int? _pressedIndex;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: _borderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(widget.items.length, (index) {
            final item = widget.items[index];
            final isSelected = index == widget.currentIndex;
            final isHovered = index == _hoveredIndex;
            final isPressed = index == _pressedIndex;

            double targetScale = 1.0;
            if (isPressed) {
              targetScale = 0.92;
            } else if (isHovered && !isSelected) {
              targetScale = 1.04;
            }
            final Color activeBgColor = _primaryEmerald;
            final Color inactiveBgColor = isHovered
                ? _primaryEmerald.withValues(alpha: 0.08)
                : Colors.transparent;

            final Color backgroundColor = isSelected ? activeBgColor : inactiveBgColor;
            final Color foregroundColor = isSelected ? Colors.white : _inactiveSlate;
            final IconData currentIcon = isSelected ? item.activeIcon : item.icon;

            return Expanded(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) {
                  setState(() {
                    _hoveredIndex = index;
                  });
                },
                onExit: (_) {
                  setState(() {
                    if (_hoveredIndex == index) {
                      _hoveredIndex = null;
                    }
                  });
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (_) {
                    setState(() {
                      _pressedIndex = index;
                    });
                  },
                  onTapUp: (_) {
                    setState(() {
                      _pressedIndex = null;
                    });
                    widget.onTap(index);
                  },
                  onTapCancel: () {
                    setState(() {
                      _pressedIndex = null;
                    });
                  },
                  child: AnimatedScale(
                    scale: targetScale,
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeInOut,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: _primaryEmerald.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                currentIcon,
                                size: 20,
                                color: foregroundColor,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: foregroundColor,
                                ),
                              ),
                            ],
                          ),
                          if (item.badgeCount != null && item.badgeCount! > 0)
                            Positioned(
                              top: -2,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  item.badgeCount! > 99 ? '99+' : '${item.badgeCount}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? _primaryEmerald : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
