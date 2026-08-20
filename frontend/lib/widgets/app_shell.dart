part of ridemate_ai;

class ThemedShell extends StatelessWidget {
  const ThemedShell({
    required this.user,
    required this.title,
    required this.onLogout,
    required this.body,
    required this.bottomBar,
    super.key,
  });

  final AppUser user;
  final String title;
  final VoidCallback onLogout;
  final Widget body;
  final Widget bottomBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.bg, AppColors.bgAlt],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth >= 900 ? 1120.0 : 500.0;
              final horizontalPadding =
                  constraints.maxWidth >= 900 ? 24.0 : 0.0;

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Column(
                      children: [
                        AppTopBar(
                          title: title,
                          subtitle: user.fullName,
                          onLogout: onLogout,
                        ),
                        Expanded(child: body),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: SafeArea(top: false, child: bottomBar),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
