// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file. (https://github.com/efortuna/dwmpr/blob/master/LICENSE)

/// Set of hand-crafted JSON parsers for GraphQL responses

import 'dart:convert';
import 'pullrequest.dart';
import 'issue.dart';
import 'repository.dart';
import 'timeline.dart';
import 'user.dart';

/// Parses a Github GraphQL user response
User parseUser(String resBody) {
  final jsonRes = json.decode(resBody)['data'];
  final userJson = jsonRes['viewer'] ?? jsonRes['user'];
  return User(userJson['login'], userJson['name'], userJson['avatarUrl']);
}

/// Parses a Github GraphQL pull request reviews response
/// // NOT USED
List<PullRequest> parseOpenPullRequestReviews(String resBody) {
  List jsonRes = json.decode(resBody)['data']['search']['edges'];
  return jsonRes.map((edge) {
    final node = edge['node'];
    final orgName = node['organization']['login'];
    final repoName = node['repository']['name'];
    final repoUrl = node['repository']['url'];
    final repoStarCount = node['repository']['stargazers']['totalCount'];
    final repo = Repository(repoName, repoUrl, orgName, repoStarCount);

    final prId = node['id'];
    final prTitle = node['title'];
    final prUrl = node['url'];
    final pr = PullRequest(prId, prTitle, prUrl, repo, '', 0);

    return pr;
  }).toList();
}

// -------------------------------------------------------------------------------------
// NON CHROMIUM AUTHOR CODE BELOW (the code below is under MIT license)

int parseBranches(String resBody) {
  int jsonRes =
      json.decode(resBody)['data']['repository']['refs']['totalCount'];
  return jsonRes;
}

int parseReleases(String resBody) {
  int jsonRes =
      json.decode(resBody)['data']['repository']['refs']['totalCount'];
  return jsonRes;
}

List<PullRequest> parsePullRequests(String resBody, String owner) {
  List jsonRes =
      json.decode(resBody)['data']['repository']['pullRequests']['nodes'];
  // print('json');
  //print(jsonRes.toString());

  Map repoInfo = json.decode(resBody)['data']['repository'];
  //print(repoInfo['stargazers']);
  Repository repo = Repository(repoInfo['name'], repoInfo['url'],
      repoInfo['stargazers']['totalCount'], owner);

  List<PullRequest> prs = [];
  for (var i = 0; i < jsonRes.length; i++) {
    prs.add(PullRequest(
        jsonRes[i]['id'],
        jsonRes[i]['title'],
        jsonRes[i]['url'],
        repo,
        jsonRes[i]['author']['login'],
        jsonRes[i]['number']));
  }

  return prs;
}

List<Issue> parseIssues(String resBody, String owner) {
  List jsonRes = json.decode(resBody)['data']['repository']['issues']['nodes'];

  Map repoInfo = json.decode(resBody)['data']['repository'];
  Repository repo = Repository(repoInfo['name'], repoInfo['url'],
      repoInfo['stargazers']['totalCount'], owner);

  List<Issue> issues = [];
  for (var i = 0; i < jsonRes.length; i++) {
    issues.add(Issue(
        jsonRes[i]['title'],
        jsonRes[i]['id'],
        jsonRes[i]['url'],
        repo,
        jsonRes[i]['author']['login'],
        jsonRes[i]['state'],
        jsonRes[i]['number']));
  }
  //print (issues.toString());
  return issues;
}

List<TimelineItem> parsePRTimeline(String resBody, PullRequest pr) {
  List jsonRes = json.decode(resBody)['data']['repository']['pullRequest']
      ['timeline']['edges'];

  List<TimelineItem> prTimeline = [];
  for (var i = 0; i < jsonRes.length; i++) {
    Map temp = jsonRes[i]['node'];
    if (temp.keys.contains('bodyText')) {
      prTimeline.add(IssueComment(pr, null, temp['id'], temp['url'], "",
          temp['author']['login'], temp['bodyText']));
    } else if (temp.keys.contains('message')) {
      if (temp['author']['user'] == null) {
        prTimeline.add(Commit(
          pr,
          null,
          temp['id'],
          temp['url'],
          "",
          "",
          temp['message'],
        ));
      } else {
        prTimeline.add(Commit(
          pr,
          null,
          temp['id'],
          temp['url'],
          "",
          temp['author']['user']['login'],
          temp['message'],
        ));
      }
    } else if (temp.keys.contains('label')) {
      prTimeline.add(LabeledEvent(pr, null, temp['id'], temp['label']['url'],
          "", temp['actor']['login'], temp['label']['name']));
    }
  }
  return prTimeline;
}

List<TimelineItem> parseIssueTimeline(String resBody, Issue issue) {
  List jsonRes =
      json.decode(resBody)['data']['repository']['issue']['timeline']['edges'];

  List<TimelineItem> issueTimeline = [];
  for (var i = 0; i < jsonRes.length; i++) {
    Map temp = jsonRes[i]['node'];
    if (temp.keys.contains('bodyText')) {
      issueTimeline.add(IssueComment(null, issue, temp['id'], temp['url'], "",
          temp['author']['login'], temp['bodyText']));
    } else if (temp.keys.contains('message')) {
      if (temp['author']['user'] == null) {
        issueTimeline.add(Commit(
          null,
          issue,
          temp['id'],
          temp['url'],
          "",
          "",
          temp['message'],
        ));
      } else {
        issueTimeline.add(Commit(
          null,
          issue,
          temp['id'],
          temp['url'],
          "",
          temp['author']['user']['login'],
          temp['message'],
        ));
      }
    } else if (temp.keys.contains('label')) {
      issueTimeline.add(LabeledEvent(
          null,
          issue,
          temp['id'],
          temp['label']['url'],
          "",
          temp['actor']['login'],
          temp['label']['name']));
    }
  }
  return issueTimeline;
}
