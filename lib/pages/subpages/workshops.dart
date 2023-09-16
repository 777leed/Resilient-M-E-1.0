// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, prefer_const_constructors_in_immutables, camel_case_types

import 'package:flutter/material.dart';
import 'package:montoring_app/components/MyWorkshops.dart';
import 'package:montoring_app/components/myProject.dart';
import 'package:montoring_app/components/myTitle.dart';

class onlyWorkshops extends StatelessWidget {
  const onlyWorkshops({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 20,
        ),
        myTitle(title: "Workshops", icon: Icon(Icons.track_changes_rounded)),
        SizedBox(
          height: 10,
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          MyWorkshops(
              img: 'Assets/images/earth.png', title: "Sustainability Wokrshop"),
          MyWorkshops(
              img: 'Assets/images/teamwork.png', title: "Group Management"),
          MyWorkshops(
              img: 'Assets/images/business.png', title: "Business Model"),
        ]),
      ],
    );
  }
}
