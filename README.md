# Millrace

## Usage

```
class UsersController

  before_action Millrace::RateLimit.new(
    name: "follows",
    rate: 1/60.0, # 1 request per minute
    window: 1.minute,
    penalty: 10.minutes,
  ), only: :create

  rescue_from Millrace::RateLimited do |error|
    # perhaps record metrics here
    response.set_header "Retry-After", error.retry_after
    head :too_many_requests
  end

...

end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/millrace. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/millrace/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Millrace project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/millrace/blob/main/CODE_OF_CONDUCT.md).
