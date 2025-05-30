import 'package:flutter/material.dart';

class NewsFeedScreen extends StatefulWidget {
  const NewsFeedScreen({super.key});

  @override
  State<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen> {
  String selectedSortOption = 'Most Relevant'; // Default selected option

  // Method to build the sorting options
  Widget buildSortOptions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end, // Align to the right
      children: [
        _buildSortOption('Most Relevant'),
        Icon(Icons.arrow_drop_down, color: Colors.black),
      ],
    );
  }

  // Method to create a clickable sort option
  Widget _buildSortOption(String option) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedSortOption = option; // Update the selected sort option
          });
        },
        child: Text(
          option,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: selectedSortOption == option ? Colors.blue : Colors.black,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text(
          "Facebook",
          style: TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: Colors.black),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.message, color: Colors.black),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Post Input Section
            _buildPostInput(),
            const Divider(),

            // Posts Section
            const NewsPost(
              userName: 'Jhoy Paulino',
              postContent: 'My GF is so beautiful!',
              userImage: 'assets/images/pogi.jpg',
              postImage: 'assets/images/hii.jpg',
            ),
          ],
        ),
      ),
    );
  }

  // Post Input Bar (with avatar and text field)
  Widget _buildPostInput() {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: AssetImage('assets/images/pogi.jpg'),
      ),
      title: TextField(
        decoration: InputDecoration(
          hintText: "What's on your mind?",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[200],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 10,
          ),
        ),
      ),
      trailing: const Icon(Icons.photo, color: Colors.green),
    );
  }
}

class NewsPost extends StatelessWidget {
  final String userName;
  final String postContent;
  final String userImage;
  final String postImage;

  const NewsPost({
    super.key,
    required this.userName,
    required this.postContent,
    required this.userImage,
    required this.postImage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info Row
          ListTile(
            leading: CircleAvatar(backgroundImage: AssetImage(userImage)),
            title: Text(
              userName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text("October 11"),
            trailing: const Icon(Icons.more_horiz),
          ),

          // Post Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(postContent),
          ),
          const SizedBox(height: 8),
          // Centered Post Image
          Center(
            child: Image.asset(
              postImage,
              height: 600,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          // Likes, Comments, Shares
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.thumb_up, color: Colors.blue, size: 18),
                    const SizedBox(width: 5),
                    Text("1k", style: TextStyle(color: Colors.grey[700])),
                  ],
                ),
                Text(
                  "10 Comments • 24 Shares",
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          const Divider(),

          // Sort Options for Comments (Most Relevant, Newest, etc.)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: buildSortOptions(context), // Add this line
          ),

          const Divider(),

          // Like, Comment, Share Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPostAction(Icons.thumb_up_alt_outlined, "Like"),
              _buildPostAction(Icons.comment_outlined, "Comment"),
              _buildPostAction(Icons.share_outlined, "Share"),
            ],
          ),

          const Divider(),

          // Comment Input Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundImage: AssetImage('assets/images/pogi.jpg'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Write a comment...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 5),
                          Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.grey,
                          ), // Speech bubble
                          SizedBox(width: 8),
                          Icon(
                            Icons.emoji_emotions_outlined,
                            color: Colors.grey,
                          ), // Emoji
                          SizedBox(width: 8),
                          Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.grey,
                          ), // Camera
                          SizedBox(width: 8),
                          Icon(Icons.gif, color: Colors.grey), // GIF
                          SizedBox(width: 8),
                          Icon(
                            Icons.sticky_note_2_outlined,
                            color: Colors.grey,
                          ), // Sticker
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Method to build sorting options for comments
  Widget buildSortOptions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end, // Align to the right
      children: [
        _buildSortOption('Most Relevant'),
        Icon(Icons.arrow_drop_down, color: Colors.black),
      ],
    );
  }

  // Method to create a clickable sort option
  Widget _buildSortOption(String option) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: GestureDetector(
        onTap: () {
          // You can add sorting functionality here
        },
        child: Text(
          option,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }

  Widget _buildPostAction(IconData icon, String label) {
    return TextButton.icon(
      onPressed: () {},
      icon: Icon(icon, color: Colors.grey[700]),
      label: Text(label, style: TextStyle(color: Colors.grey[700])),
    );
  }
}
