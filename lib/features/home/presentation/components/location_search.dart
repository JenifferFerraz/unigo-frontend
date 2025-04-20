import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LocationSearch extends StatelessWidget {
  final List<String> locations = [
    'Bloco I, Sala 203',
    'Auditório Bloco F',
    'Bloco H, Sala 101',
    'Bloco A, Sala 108',
    'Secretaria Geral',
  ];

  LocationSearch({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return const Iterable<String>.empty();
        }
        return locations.where((String option) {
          return option.toLowerCase()
              .contains(textEditingValue.text.toLowerCase());
        });
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              color: Colors.white,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  return ListTile(
                    title: Text(option),
                    onTap: () {
                      onSelected(option);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: 'Buscar local...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.search),
          ),
        );
      },
    );
  }
}
