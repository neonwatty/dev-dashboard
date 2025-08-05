# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **developer-focused aggregation dashboard** built with Rails 8 + Vite + Tailwind CSS that collects and surfaces new questions, issues, and discussions from various developer communities including:

- Hugging Face and PyTorch forums (Discourse-based)
- GitHub Issues from specified repositories
- Hacker News discussions
- Reddit subreddits

The goal is to surface opportunities for developers to contribute by answering questions, troubleshooting bugs, or engaging with OSS discussions.

## Tech Stack

- **Web Framework**: Ruby on Rails 8
- **JavaScript**: Vite + vite_ruby for asset bundling
- **Styling**: Tailwind CSS
- **Database**: SQLite for data persistence
- **Background Jobs**: In-memory (async) or SQLite-backed ActiveJob queues
- **LLM Integration**: ruby_llm gem for AI-powered reply suggestions

## Key Architecture Components

### Data Models
- **Post**: Stores aggregated content from various sources with fields for source, external_id, title, URL, author, tags, status, priority_score, and LLM-generated reply drafts
- **Source**: Manages different data sources (GitHub repos, forums, RSS feeds) with configuration, credentials, and connection status

### Background Jobs
- Source-specific fetch jobs for each platform (Hugging Face, PyTorch, GitHub, Hacker News, Reddit)
- `SuggestPostReplyJob`: Uses LLM to generate draft responses
- `ScorePostsJob`: Computes relevance/urgency scores for posts

### LLM Integration
- Uses `ruby_llm` gem for multi-provider LLM support (OpenAI, Anthropic, Ollama, Hugging Face, AWS Bedrock)
- Generates helpful reply suggestions for community posts
- Provider selection is configurable per source or user

## Development Status

**Current State**: This appears to be a new project with only basic documentation. The actual Rails application has not been scaffolded yet.

**Next Steps (based on PRD)**:
1. Scaffold Rails 8 app with Vite + Tailwind
2. Create Post and Source models
3. Implement data fetching for Hugging Face and PyTorch forums
4. Build basic feed UI with filtering capabilities

## External Integrations

- **Discourse Forums**: Uses `discourse_api` gem for Hugging Face and PyTorch forums
- **GitHub**: Uses `octokit` gem for GitHub Issues API
- **Reddit**: Uses `redd` gem for Reddit API access
- **RSS Feeds**: Uses `feedjira` gem for Hacker News and other RSS sources

## Security Considerations

- API credentials are encrypted and stored securely
- OAuth tokens managed per source in the profile screen
- Environment variables used for LLM provider API keys