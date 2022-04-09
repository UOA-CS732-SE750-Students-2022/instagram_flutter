import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instagram_flutter/resources/auth_methods.dart';
import 'package:instagram_flutter/resources/firestore_methods.dart';
import 'package:instagram_flutter/screens/login_screen.dart';
import 'package:instagram_flutter/utils/colors.dart';
import 'package:instagram_flutter/utils/global_variables.dart';
import 'package:instagram_flutter/utils/utils.dart';
import 'package:instagram_flutter/widgets/follow_button.dart';
import 'package:instagram_flutter/widgets/status_column.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;
  final bool needAppBar;
  const ProfileScreen({Key? key, required this.uid, required this.needAppBar})
      : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  var userData = {};
  int postLen = 0;
  int followers = 0;
  int following = 0;
  bool isFollowing = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getData();
  }

  getData() async {
    setState(() {
      isLoading = true;
    });
    try {
      var userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

      var postSnap = await FirebaseFirestore.instance
          .collection('posts')
          .where('uid', isEqualTo: widget.uid)
          .get();

      userData = userSnap.data()!;
      followers = userSnap.data()!['followers']!.length;
      following = userSnap.data()!['following']!.length;
      isFollowing = userSnap
          .data()!['followers']
          .contains(FirebaseAuth.instance.currentUser!.uid);
      postLen = postSnap.docs.length;
      setState(() {});
    } catch (e) {
      showSnackBar(e.toString(), context);
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isCurrentUser = FirebaseAuth.instance.currentUser!.uid == widget.uid;
    return getProfile(isLoading, width, isCurrentUser);
  }

  Widget getProfile(bool isLoading, double width, bool isCurrentUser) {
    if (isLoading) {
      return Container(
        decoration: const BoxDecoration(
          color: mobileBackgroundColor,
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return Scaffold(
        appBar: !widget.needAppBar
            ? null
            : AppBar(
                backgroundColor: mobileBackgroundColor,
                title: Text(userData['username']),
                centerTitle: false,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
        body: Container(
          margin: EdgeInsets.symmetric(
            horizontal: width > webScreenSize ? width * 0.3 : 0,
          ),
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              // status bar, which included avatar and follow info
              getStatusBar(),
              // user info
              getUsername(userData['username']),
              // bio
              getBio(userData['bio']),
              // all the posts from this user
              getControlBar(isCurrentUser),
              // as the gap between the control bar and the posts
              const SizedBox(height: 16),
              const Divider(),
              getPostContent(),
            ],
          ),
        ),
      );
    }
  }

  Row getStatusBar() {
    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: CachedNetworkImageProvider(
                userData['photoUrl'],
              ),
            ),
          ),
        ),
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              StatusColumn(
                num: postLen,
                label: 'posts',
              ),
              StatusColumn(
                num: followers,
                label: 'followers',
              ),
              StatusColumn(
                num: following,
                label: 'following',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Row getControlBar(bool isCurrentUser) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        isCurrentUser
            ? FollowButton(
                text: 'Sign Out',
                backgroundColor: mobileBackgroundColor,
                textColor: primaryColor,
                borderColor: secondaryColor,
                function: () async {
                  await AuthMethods().signOut();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
              )
            : isFollowing
                ? FollowButton(
                    text: 'Unfollow',
                    backgroundColor: primaryColor,
                    textColor: Colors.black,
                    borderColor: primaryColor,
                    function: () async {
                      await FirestoreMethods().followUser(
                          FirebaseAuth.instance.currentUser!.uid, widget.uid);

                      setState(() {
                        isFollowing = false;
                        followers--;
                      });
                    },
                  )
                : FollowButton(
                    text: 'Follow',
                    backgroundColor: blueColor,
                    textColor: primaryColor,
                    borderColor: blueColor,
                    function: () async {
                      await FirestoreMethods().followUser(
                          FirebaseAuth.instance.currentUser!.uid, widget.uid);
                      setState(() {
                        isFollowing = true;
                        followers++;
                      });
                    },
                  )
      ],
    );
  }

  Container getUsername(String username) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(top: 16, bottom: 2),
      child: Text(
        username,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Container getBio(String bio) {
    return Container(
      alignment: Alignment.centerLeft,
      child: Text(
        userData['bio'],
      ),
    );
  }

  FutureBuilder getPostContent() {
    return FutureBuilder(
      future: FirebaseFirestore.instance
          .collection('posts')
          .where('uid', isEqualTo: widget.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          itemCount: (snapshot.data as dynamic).docs.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 5,
              mainAxisSpacing: 1.5,
              childAspectRatio: 1),
          itemBuilder: (context, index) {
            // get the post data
            DocumentSnapshot snap = (snapshot.data as dynamic).docs[index];
            return CachedNetworkImage(
              imageUrl: snap['postUrl'],
              imageBuilder: (context, imageProvider) => Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
