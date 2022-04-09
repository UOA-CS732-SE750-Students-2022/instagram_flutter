import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instagram_flutter/models/post.dart';
import 'package:instagram_flutter/resources/storage_methods.dart';
import 'package:uuid/uuid.dart';

class FirestoreMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // upload post
  Future<String> uploadPosts(String description, Uint8List file, String uid,
      String username, String profImage) async {
    String res = "Some error occurred";
    try {
      String photoUrl =
          await StorageMethods().uploadImageToStorage("posts", file, true);

      String postId = const Uuid().v1();
      Post post = Post(
        description: description,
        uid: uid,
        username: username,
        postId: postId,
        datePublished: DateTime.now(),
        postUrl: photoUrl,
        profImage: profImage,
        likes: [],
      );

      _firestore.collection('posts').doc(postId).set(post.toJson());
      res = "success";
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  Future<void> likePosts(String postId, String uid, List likes) async {
    try {
      if (likes.contains(uid)) {
        await _firestore.collection("posts").doc(postId).update({
          "likes": FieldValue.arrayRemove([uid]),
        });
      } else {
        await _firestore.collection("posts").doc(postId).update({
          "likes": FieldValue.arrayUnion([uid]),
        });
      }
    } catch (err) {
      print(err.toString());
    }
  }

  // add comment to firestore
  Future<void> postComment(String postId, String text, String uid, String name,
      String profImage) async {
    try {
      if (text.isNotEmpty) {
        String commendId = const Uuid().v1();
        // comments is the subcollection of posts
        await _firestore
            .collection("posts")
            .doc(postId)
            .collection('comments')
            .doc(commendId)
            .set({
          'profImage': profImage,
          "text": text,
          'uid': uid,
          "name": name,
          "commentId": commendId,
          "datePublished": DateTime.now()
        });
      } else {
        print("Text is empty");
      }
    } catch (err) {
      print(err.toString());
    }
  }

  // delete the post
  Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection("posts").doc(postId).delete();
    } catch (err) {
      print(err.toString());
    }
  }

  // follow user
  Future<void> followUser(String currentUserId, String userId) async {
    try {
      DocumentSnapshot snap =
          await _firestore.collection("users").doc(currentUserId).get();
      List following = (snap.data() as dynamic)['following']!;

      if (following.contains(userId)) {
        await _firestore.collection("users").doc(userId).update({
          "followers": FieldValue.arrayRemove([currentUserId]),
        });

        await _firestore.collection("users").doc(currentUserId).update({
          "following": FieldValue.arrayRemove([userId]),
        });
      } else {
        await _firestore.collection("users").doc(userId).update({
          "followers": FieldValue.arrayUnion([currentUserId]),
        });

        await _firestore.collection("users").doc(currentUserId).update({
          "following": FieldValue.arrayUnion([userId]),
        });
      }
    } catch (err) {
      print(err.toString());
    }
  }
}
