import 'package:corexchat/src/global/global.dart';
import 'package:flutter/material.dart';

class VerificationLogoWidget extends StatelessWidget {
  final String? logoUrl;
  final double size;
  final EdgeInsetsGeometry? margin;

  const VerificationLogoWidget({
    Key? key,
    required this.logoUrl,
    this.size = 16,
    this.margin = const EdgeInsets.only(left: 5),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: SizedBox(
          width: size,
          height: size,
          child: CustomCachedNetworkImage(
            imageUrl: logoUrl ?? "",
            errorWidgeticon: Icon(
              Icons.verified,
              size: size,
              color: Colors.blue,
            ),
          ),
        ),
      ),
    );
  }
}
