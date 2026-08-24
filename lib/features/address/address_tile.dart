import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'package:wallet_test/core/theme/app_tokens.dart';
import 'package:wallet_test/features/address/address_display.dart';
import 'package:wallet_test/features/address/address_tile_bloc.dart';

class AddressTile extends StatefulWidget {
  const AddressTile({
    super.key,
    required this.address,
    required this.network,
  });

  final String address;
  final String network;

  @override
  State<AddressTile> createState() => _AddressTileState();
}

class _AddressTileState extends State<AddressTile> {
  late final AddressTileBloc _bloc = GetIt.instance<AddressTileBloc>();

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textScaleFactor = MediaQuery.textScaleFactorOf(context);

    return SizedBox(
      height: AppTokens.cellHeight,
      child: ColoredBox(
        color: AppTokens.surface,
        child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.horizontalPadding,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.network,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTokens.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTokens.verticalGap),
                  Text(
                    formatAddressForCell(widget.address, textScaleFactor),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTokens.textPrimary,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTokens.gapTextIcon),
            SizedBox(
              width: AppTokens.tapTarget,
              height: AppTokens.tapTarget,
              child: BlocBuilder<AddressTileBloc, AddressTileState>(
                bloc: _bloc,
                builder: (context, state) {
                  final icon = state.error != null
                      ? Icons.error_outline
                      : state.copied
                          ? Icons.check
                          : Icons.copy;
                  final color = state.error != null
                      ? AppTokens.danger
                      : state.copied
                          ? AppTokens.success
                          : AppTokens.textSecondary;

                  return IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _bloc.add(CopyTapped(widget.address)),
                    icon: Icon(
                      icon,
                      size: AppTokens.iconSize,
                      color: color,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
