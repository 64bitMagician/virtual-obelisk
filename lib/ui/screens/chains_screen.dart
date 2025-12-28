import 'package:flutter/material.dart';
import '../../data/models/chain.dart';
import '../../data/repositories/mock_repository.dart';
import '../widgets/chain_card.dart';

class ChainsScreen extends StatefulWidget {
  const ChainsScreen({super.key});

  @override
  State<ChainsScreen> createState() => _ChainsScreenState();
}

class _ChainsScreenState extends State<ChainsScreen> {
  final MockRepository _repository = MockRepository();
  late Future<List<Chain>> _chainsFuture;

  @override
  void initState() {
    super.initState();
    _chainsFuture = _repository.getChains();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Collaborative Chains"),
      ),
      body: FutureBuilder<List<Chain>>(
        future: _chainsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final chains = snapshot.data ?? [];

          return ListView.builder(
            itemCount: chains.length,
            itemBuilder: (context, index) {
              return Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: ChainCard(chain: chains[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}