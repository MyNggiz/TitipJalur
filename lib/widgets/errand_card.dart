import 'package:flutter/material.dart';
import '../models/errand_model.dart';

class ErrandCard extends StatelessWidget {
  final ErrandModel errand;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final bool showAction;
  final EdgeInsetsGeometry? margin;

  const ErrandCard({
    super.key,
    required this.errand,
    this.onTap,
    this.onAccept,
    this.showAction = true,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: category & requester on left, status badge on right
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        errand.category,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Oleh ${errand.requester}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: errand.status.backgroundColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: errand.status.color.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        errand.status.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: errand.status.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Item title
                Text(
                  errand.item,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Route card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.storefront_outlined,
                            size: 15,
                            color: Color(0xFF0284C7),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errand.pickup,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF334155),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            height: 10,
                            child: VerticalDivider(
                              color: Color(0xFFCBD5E1),
                              thickness: 1.2,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 15,
                            color: Color(0xFF059669),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errand.dropoff,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF334155),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Footer: tip, distance, and contextual action button
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          errand.formattedTip,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.near_me_outlined,
                              size: 12,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${errand.distanceKm.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (showAction && errand.status == OrderStatus.open)
                      ElevatedButton.icon(
                        onPressed: onAccept,
                        icon: const Icon(Icons.handshake_outlined, size: 15),
                        label: const Text('Ambil Titipan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      )
                    else if (onTap != null)
                      TextButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                        label: const Text('Detail'),
                        iconAlignment: IconAlignment.end,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF059669),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          textStyle: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
