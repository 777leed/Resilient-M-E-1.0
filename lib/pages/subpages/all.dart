// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, prefer_const_constructors_in_immutables, camel_case_types

import 'package:flutter/material.dart';
import 'package:montoring_app/components/myCard.dart';
import 'package:montoring_app/components/myProject.dart';
import 'package:montoring_app/components/myTitle.dart';
import 'package:montoring_app/pages/DisasterPage.dart';
import 'package:montoring_app/styles.dart';

class allCategories extends StatelessWidget {
  const allCategories({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 20,
        ),
        myTitle(title: "Disaster Relief", icon: Icon(Icons.warning_rounded)),
        SizedBox(
          height: 10,
        ),
        myCard(
            onTap: () {
              // Navigate to the desired page when the card is clicked
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => DisasterPage(),
                ),
              );
            },
            img: 'Assets/images/earthquake.png',
            color: CustomColors.secondaryColor,
            title: "Moroco Earthquake",
            desc:
                "Disaster Recovery for towns and villages impacted by the earthquake"),
        SizedBox(
          height: 20,
        ),
        myTitle(
            title: "Projects",
            icon: Icon(
              Icons.flag_rounded,
            )),
        SizedBox(
          height: 10,
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          myProject(
              img: 'Assets/images/earthquake.png',
              title: "Tassdert Solar Panels"),
          myProject(
              img: 'Assets/images/earthquake.png',
              title: "Tassdert Solar Panels"),
          myProject(
              img: 'Assets/images/earthquake.png',
              title: "Tassdert Solar Panels"),
        ]),
        SizedBox(
          height: 20,
        ),
        myTitle(title: "Workshops", icon: Icon(Icons.track_changes_rounded)),
        SizedBox(
          height: 10,
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          myProject(
              img: 'Assets/images/earthquake.png',
              title: "Tassdert Solar Panels"),
          myProject(
              img: 'Assets/images/earthquake.png',
              title: "Tassdert Solar Panels"),
          myProject(
              img: 'Assets/images/earthquake.png',
              title: "Tassdert Solar Panels"),
        ]),
      ],
    );
  }
}
