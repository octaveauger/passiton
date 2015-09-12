# README Passiton

## What to do when new gems are installed

Type `bundle`

## What to do when the database changes

Type:
`rake testing:empty_db` (will delete everything apart from users)
`bundle exec rake db:migrate` (will get your DB up to speed)