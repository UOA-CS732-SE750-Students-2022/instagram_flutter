import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/resources/firestore_methods.dart';
import 'package:instagram_flutter/screens/comments_screen.dart';
import 'package:instagram_flutter/utils/colors.dart';
import 'package:instagram_flutter/utils/utils.dart';
import 'package:instagram_flutter/widgets/like_animation.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:instagram_flutter/models/user.dart' as model;
import 'package:instagram_flutter/screens/profile_screen.dart';

class PostCard extends StatefulWidget {
  final snap;
  const PostCard({Key? key, required this.snap}) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool isLikeAnimating = false;
  int commentLen = 0;

  @override
  void initState() {
    super.initState();
    getComments();
  }

  void getComments() async {
    try {
      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.snap['postId'])
          .collection('comments')
          .get();

      setState(() {
        commentLen = snap.docs.length;
      });
    } catch (e) {
      showSnackBar(e.toString(), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final model.User user = Provider.of<UserProvider>(context).getUser;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: mobileBackgroundColor,
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(children: [
        // header section
        Container(
          padding: const EdgeInsets.only(
            bottom: 10,
            left: 16,
            right: 16,
          ).copyWith(right: 0),
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(
                      uid: widget.snap['uid'],
                      needAppBar: true,
                    ),
                  ),
                ),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(
                        widget.snap['profImage'],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.snap['username'],
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      )
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shrinkWrap: true,
                        children: [
                          'Delete',
                        ]
                            .map(
                              (e) => InkWell(
                                onTap: () async {
                                  await FirestoreMethods().deletePost(
                                    widget.snap['postId'],
                                  );
                                  Navigator.of(context).pop();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  child: Text(e),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.more_vert),
              )
            ],
          ),
        ),

        // image section
        GestureDetector(
          onDoubleTap: () async {
            await FirestoreMethods().likePosts(
              widget.snap['postId'],
              user.uid,
              widget.snap['likes'],
            );
            setState(() {
              isLikeAnimating = true;
            });
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.35,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: widget.snap['postUrl'].toString(),
                  imageBuilder: (context, imageProvider) => Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isLikeAnimating ? 1 : 0,
                child: LikeAnimation(
                  child: const Icon(
                    Icons.favorite,
                    color: primaryColor,
                    size: 120,
                  ),
                  isAnimating: isLikeAnimating,
                  duration: const Duration(milliseconds: 400),
                  onEnd: () {
                    setState(() {
                      isLikeAnimating = false;
                    });
                  },
                ),
              )
            ],
          ),
        ),

        // like and comment section
        Row(
          children: [
            LikeAnimation(
              isAnimating: widget.snap['likes'].contains(user.uid),
              smallLike: true,
              child: IconButton(
                onPressed: () async {
                  await FirestoreMethods().likePosts(
                    widget.snap['postId'],
                    user.uid,
                    widget.snap['likes'],
                  );
                  setState(() {
                    isLikeAnimating = true;
                  });
                },
                icon: widget.snap['likes'].contains(user.uid)
                    ? const Icon(
                        Icons.favorite,
                        color: Colors.redAccent,
                      )
                    : const Icon(
                        Icons.favorite_outline,
                        color: primaryColor,
                      ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CommentScreen(
                    snap: widget.snap,
                  ),
                ),
              ),
              icon: const Icon(Icons.comment_outlined),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.send),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.bottomRight,
                child: IconButton(
                  icon: const Icon(Icons.bookmark_outline),
                  onPressed: () {},
                ),
              ),
            )
          ],
        ),

        // description and number of comments
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefaultTextStyle(
                  style: Theme.of(context)
                      .textTheme
                      .subtitle2!
                      .copyWith(fontWeight: FontWeight.bold),
                  child: Text(
                    '${widget.snap['likes'].length} likes',
                    style: Theme.of(context).textTheme.bodyText2,
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 8),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: primaryColor,
                        fontFamily: "Montserrat",
                      ),
                      children: [
                        TextSpan(
                          text: widget.snap['username'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: ' ${widget.snap['description']}',
                        ),
                      ],
                    ),
                  ),
                ),

                // comment section
                InkWell(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'View all ${commentLen} comments',
                      style: const TextStyle(
                        fontSize: 16,
                        color: secondaryColor,
                      ),
                    ),
                  ),
                ),

                Text(
                  DateFormat.yMMMd().format(
                    widget.snap['datePublished'].toDate(),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    color: secondaryColor,
                  ),
                ),
              ]),
        )
      ]),
    );
  }
}
