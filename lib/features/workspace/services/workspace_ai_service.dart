/// Generates the mock "intelligence" behind the workspace experience.
///
/// This is the single seam for AI-generated content (titles, replies,
/// summaries, previews, action items, key facts and suggested tasks). The UI
/// never holds generated strings and the repository never invents them —
/// everything funnels through here. Sprint 2 swaps this for the real model.
///
/// Implementations must be deterministic so tests can rely on the output.
abstract interface class WorkspaceAIService {
  String titleFromPrompt(String prompt);

  /// Reply to [prompt] inside a session titled [sessionTitle]. [turn] is the
  /// zero-based index of the user message (0 = first message in a session).
  String replyTo(String sessionTitle, String prompt, int turn);

  String sessionSummary(String sessionTitle);
  String sessionPreview(String sessionTitle);
  List<String> actionItemsFor(String sessionTitle);
  List<String> keyFactsFor(String sessionTitle);
  List<String> suggestedTaskTitles(String topic);

  /// AI summary of a file's contents based on its name and type.
  String fileSummary(String fileName, String fileTypeLabel);

  /// Deterministic one-line recap of the workspace used by the daily briefing.
  String briefingRecap();
}

/// Deterministic mock: keyword-driven templates, no randomness, no network.
class MockWorkspaceAIService implements WorkspaceAIService {
  const MockWorkspaceAIService();

  @override
  String titleFromPrompt(String prompt) {
    final cleaned = prompt.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.isEmpty) return 'New session';
    final words = cleaned.split(' ').where((w) => w.isNotEmpty).take(6).toList();
    var title = words.join(' ');
    if (title.length > 40) title = '${title.substring(0, 40).trimRight()}...';
    return '${title[0].toUpperCase()}${title.substring(1)}';
  }

  @override
  String replyTo(String sessionTitle, String prompt, int turn) {
    if (turn <= 0) {
      return 'I opened a new session for "$sessionTitle".\n\n'
          'Here is the plan I would run:\n'
          '1. Break the goal into concrete steps.\n'
          '2. Draft each piece as we go.\n'
          '3. Save key decisions to workspace memory.\n\n'
          'Where should we start?';
    }
    return _replyByTopic(_topicOf(prompt), sessionTitle);
  }

  @override
  String sessionSummary(String sessionTitle) {
    return 'This session focused on "$sessionTitle". We broke the goal into '
        'steps, made the key decisions, and left the next actions clearly '
        'defined. Everything discussed here has been saved to the workspace '
        'so we can pick it back up anytime.';
  }

  @override
  String sessionPreview(String sessionTitle) {
    return 'Focused on "$sessionTitle". Decisions made and next steps set.';
  }

  @override
  List<String> actionItemsFor(String sessionTitle) {
    final topic = _topicOf(sessionTitle);
    return switch (topic) {
      _Topic.supplier => const [
          'Confirm the delivery timeline with the vendor',
          'Re-negotiate volume pricing with the second vendor',
          'Send the final order for sign-off',
        ],
      _Topic.budget => const [
          'Update the budget sheet with the latest figures',
          'Categorise this month expenses',
          'Review one optional line item',
        ],
      _Topic.admission => const [
          'Check the application deadline',
          'Gather the required documents',
          'Draft the application checklist',
        ],
      _Topic.comparison => const [
          'Build the comparison table',
          'Share the recommendation',
          'Note the chosen option in memory',
        ],
      _Topic.deadline => const [
          'Set the deadline reminder',
          'Split the deadline into daily steps',
          'Review progress before the due date',
        ],
      _Topic.draft => const [
          'Finalise the draft',
          'Send the draft for review',
          'Collect feedback',
        ],
      _Topic.summary => const [
          'Publish the week summary',
          'Move key points into tasks',
          'Archive finished work',
        ],
      _Topic.general => const [
          'Break the goal into concrete steps',
          'Draft the first deliverable',
          'Schedule a check-in',
        ],
    };
  }

  @override
  List<String> keyFactsFor(String sessionTitle) {
    final topic = _topicOf(sessionTitle);
    return switch (topic) {
      _Topic.supplier => const [
          'Vendor B has the best unit price',
          'Decision due before Friday',
          'Quotes must be presented in Naira',
        ],
      _Topic.budget => const [
          'Total stays within budget',
          'Fees are the biggest line item',
          'One optional item can be delayed',
        ],
      _Topic.admission => const [
          'Course requirements confirmed',
          'Deadline lands this week',
          'Documents list ready',
        ],
      _Topic.comparison => const [
          'Options compared',
          'Recommended option chosen',
          'Decision pending confirmation',
        ],
      _Topic.deadline => const [
          'Deadline set',
          'Reminder added to the task list',
          'Urgent step comes first',
        ],
      _Topic.draft => const [
          'Draft ready to review',
          'Tone is adjustable',
          'Recipient is the follow-up contact',
        ],
      _Topic.summary => const [
          'All key points captured',
          'Next actions listed',
          'Summary saved to the workspace',
        ],
      _Topic.general => const [
          'Session captured in workspace',
          'Next steps are clear',
          'Linked files updated',
        ],
    };
  }

  @override
  String briefingRecap() {
    return 'GANO is on track. Two tasks finished since yesterday and the '
        'supplier decision is the only blocker this week.';
  }

  @override
  String fileSummary(String fileName, String fileTypeLabel) {
    final name = fileName;
    return switch (_topicOf(name)) {
      _Topic.comparison => 'This $fileTypeLabel holds a comparison of the '
          'available options. It lists the key trade-offs, the recommended '
          'choice and the reasons behind it.',
      _Topic.supplier => 'This $fileTypeLabel captures the supplier quotes. '
          'It lists three pricing options with unit prices, delivery windows '
          'and payment terms, all presented in Naira as preferred.',
      _Topic.budget => 'This $fileTypeLabel holds the school budget. Fees are '
          'the biggest line item and the total stays within the planned '
          'amount; one optional item can be delayed.',
      _Topic.admission => 'This $fileTypeLabel covers the admission '
          'requirements for the course — subjects, cut-off mark and the '
          'documents needed for the application.',
      _Topic.deadline => 'This $fileTypeLabel tracks a deadline. The key '
          'milestone lands this week and the urgent step is listed first.',
      _Topic.summary => 'This $fileTypeLabel is a recap of what happened in '
          'the workspace — main decisions, finished work and next actions.',
      _Topic.draft => 'This $fileTypeLabel is a draft waiting for review. '
          'The tone can be adjusted before it is sent.',
      _Topic.general => 'This $fileTypeLabel contains material referenced '
          'across the workspace. Banataq can pull key points from it on '
          'request.',
    };
  }

  @override
  List<String> suggestedTaskTitles(String topic) {
    return switch (_topicOf(topic)) {
      _Topic.supplier => const [
          'Follow up on the best supplier quote',
          'Create the supplier comparison table',
          'Confirm the delivery timeline with the vendor',
        ],
      _Topic.budget => const [
          'Update the workspace budget sheet',
          'Categorise this month expenses',
          'Review one optional line item',
        ],
      _Topic.admission => const [
          'Check the admission deadline',
          'Gather the required documents',
          'Draft the application checklist',
        ],
      _Topic.comparison => const [
          'Build the comparison table',
          'Share the recommendation',
          'Note the chosen option',
        ],
      _Topic.deadline => const [
          'Set the deadline reminder',
          'Split the deadline into daily steps',
          'Review progress before the due date',
        ],
      _Topic.draft => const [
          'Finalise the draft',
          'Send the draft for review',
          'Collect feedback',
        ],
      _Topic.summary => const [
          'Publish the week summary',
          'Move key points into tasks',
          'Archive finished work',
        ],
      _Topic.general => const [
          'Break the goal into concrete steps',
          'Draft the first deliverable',
          'Schedule a check-in',
        ],
    };
  }

  String _replyByTopic(_Topic topic, String sessionTitle) {
    return switch (topic) {
      _Topic.supplier => 'Here is what we know for "$sessionTitle":\n\n'
          '1. Quote received — follow up on the missing item.\n'
          '2. Delivery window — confirm before Friday.\n'
          '3. Payment terms — Naira, as agreed.\n\n'
          'I can draft the follow-up message now if you want.',
      _Topic.comparison => 'I put the options side by side for "$sessionTitle":\n\n'
          'Quick read:\n'
          '- Cheapest unit price: Option C (needs the minimum order).\n'
          '- Fastest delivery: Option B.\n'
          '- Best value overall: Option B for a small batch.\n\n'
          'Recommendation: go with Option B for this batch, then re-negotiate '
          'volume pricing with C.\n\n'
          'Want me to build the comparison table as a file you can send?',
      _Topic.budget => 'I worked through the numbers for "$sessionTitle":\n\n'
          '- Total estimated cost: within budget.\n'
          '- Biggest line item: fees.\n'
          '- Trim opportunity: delay one optional item by a week.\n\n'
          'I can turn this into a simple budget table you can share.',
      _Topic.admission => 'For "$sessionTitle" I pulled together the key requirements:\n\n'
          '- Core subjects required for the course.\n'
          '- Cut-off mark for the current year.\n'
          '- Documents needed for the application.\n\n'
          'Next step is checking the deadline — want me to add it to the task list?',
      _Topic.deadline => 'Here is the plan to hit the deadline for "$sessionTitle":\n\n'
          '1. Do the urgent step first.\n'
          '2. Send the draft for review.\n'
          '3. Finalise before the due date.\n\n'
          'I added a reminder to the task list.',
      _Topic.summary => 'Here is the recap of "$sessionTitle":\n\n'
          '- What we covered: the main decisions and open questions.\n'
          '- What is done: the pieces we finished.\n'
          '- What is next: the actions waiting on someone.\n\n'
          'I can turn this into a one-page summary file if useful.',
      _Topic.draft => 'Here is the draft for "$sessionTitle":\n\n'
          'Hi,\n\n'
          'Following up on our conversation, here is the next step. Let me '
          'know when you are ready and I will tighten the wording.\n\n'
          'Want me to adjust the tone before you send it?',
      _Topic.general => 'Here is what I can do next for "$sessionTitle":\n\n'
          '1. Draft the next step for you.\n'
          '2. Summarise what we covered.\n'
          '3. Turn the outcome into tasks.\n\n'
          'Just tell me which one to run.',
    };
  }

  _Topic _topicOf(String text) {
    final t = text.toLowerCase();
    if (t.contains('table') ||
        t.contains('compare') ||
        t.contains('decision') ||
        t.contains('option')) {
      return _Topic.comparison;
    }
    if (t.contains('quote') ||
        t.contains('supplier') ||
        t.contains('price') ||
        t.contains('vendor') ||
        t.contains('alhaji')) {
      return _Topic.supplier;
    }
    if (t.contains('budget') ||
        t.contains('cost') ||
        t.contains('fee') ||
        t.contains('money')) {
      return _Topic.budget;
    }
    if (t.contains('admission') ||
        t.contains('requirement') ||
        t.contains('jamb') ||
        t.contains('university') ||
        t.contains('school')) {
      return _Topic.admission;
    }
    if (t.contains('deadline') ||
        t.contains('due') ||
        t.contains('schedule') ||
        t.contains('friday') ||
        t.contains('tomorrow') ||
        t.contains('plan')) {
      return _Topic.deadline;
    }
    if (t.contains('summar') || t.contains('recap') || t.contains('week')) {
      return _Topic.summary;
    }
    if (t.contains('draft') ||
        t.contains('email') ||
        t.contains('write') ||
        t.contains('message')) {
      return _Topic.draft;
    }
    return _Topic.general;
  }
}

enum _Topic {
  comparison,
  supplier,
  budget,
  admission,
  deadline,
  summary,
  draft,
  general,
}
