import 'package:flutter/material.dart';
import '../theme.dart';

class RoundedButton extends StatelessWidget {
	final String label;
	final VoidCallback? onPressed;
	final IconData? icon;
	final bool fullWidth;

	const RoundedButton({
		super.key,
		required this.label,
		this.onPressed,
		this.icon,
		this.fullWidth = true,
	});

	@override
	Widget build(BuildContext context) {
		return SizedBox(
			width: fullWidth ? double.infinity : null,
			child: ElevatedButton.icon(
				icon: icon != null ? Icon(icon, size: 18) : SizedBox.shrink(),
				label: Text(label, style: Theme.of(context).textTheme.titleMedium),
				onPressed: onPressed,
				style: ElevatedButton.styleFrom(
					backgroundColor: AppColors.primary,
					padding: EdgeInsets.symmetric(vertical: 14, horizontal: 18),
					shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
				),
			),
		);
	}
}

