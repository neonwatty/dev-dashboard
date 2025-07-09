# Dev Dashboard

A developer-focused aggregation dashboard that collects and surfaces opportunities for contributing to open source communities.

## Features

- **Multi-Platform Content Aggregation**: Collect posts from HuggingFace, PyTorch forums, GitHub issues, Reddit, and RSS feeds
- **Smart Filtering**: Filter by keyword, source, tag, or status
- **Priority Scoring**: Automatically rank posts by relevance and urgency
- **Status Management**: Track read/unread/ignored/responded posts
- **Real-time Updates**: Manual refresh and background job processing
- **Responsive UI**: Clean, modern interface built with Tailwind CSS

## Tech Stack

- **Backend**: Ruby on Rails 8.0.2
- **Frontend**: Vite + Tailwind CSS
- **Database**: SQLite
- **Background Jobs**: ActiveJob
- **Asset Pipeline**: Vite with Hot Module Replacement

## Quick Start

### Prerequisites

- Ruby 3.4.2+
- Node.js 18+
- SQLite3

### Installation

```bash
git clone https://github.com/neonwatty/dev-dashboard.git
cd dev-dashboard
bundle install
npm install
```

### Database Setup

```bash
rails db:create
rails db:migrate
rails db:seed
```

### Development

```bash
# Start the Rails server (runs on port 3002)
rails server

# In another terminal, start Vite dev server
bin/vite dev
```

Visit `http://localhost:3002` or `http://dev-dashboard.localhost:3002`

## Usage

1. **Add Sources**: Navigate to `/sources` to add HuggingFace, PyTorch, or other community sources
2. **View Dashboard**: The main dashboard shows aggregated posts with filtering options
3. **Manage Posts**: Mark posts as read, ignored, or responded to track your engagement
4. **Refresh Content**: Use manual refresh or background jobs to fetch new content

## Configuration

- **Port**: Configured to run on port 3002 (configurable in `config/puma.rb`)
- **Subdomain**: Set up for `dev-dashboard.localhost` (configurable in `config/environments/development.rb`)
- **Sources**: Add new sources through the web interface or via Rails console

## Development

### Running Tests

```bash
rails test
```

### Background Jobs

```bash
# Manually trigger content fetching
rails runner "FetchHuggingFaceJob.perform_now"
rails runner "FetchPytorchJob.perform_now"
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is open source and available under the [MIT License](LICENSE).
