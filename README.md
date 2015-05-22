# AuditLogger

This gem implements simple and separated Rails Logger for any action that you want.
If you want separate logger for email notification, data import, migration this is what you need.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'audit_logger'
```

And then execute:

    $ bundle

After running bundle install, run the generator:

    $ rails generate audit:install

## Usage
  The installer creates `config/initializers/audit.rb` file which implement dummy setup of audit logger.

    ```ruby
      unless Rails.env.test?
        log_path_with_env = "#{Rails.root}/log/audit/#{Rails.env}"

        ::ERROR_LOG = Audit::AuditLogger.new("#{log_path_with_env}_error.log", timestamp: true, pid: true, severity: true, thread: true)

        # ::AUDIT_NULL   = Audit::AuditLogger.new(File::NULL)
        # ::AUDIT_STDOUT = Audit::AuditLogger.new(STDOUT)
        # ::PRODUCT_LOG  = AuditLogger::Audit.new("#{log_path_with_env}_product.log")
      end
    ```


  By default all files will be generated in `log/audit/` folder, if you want to change this behavior just change `#{Rails.root}/log/audit/#{Rails.env}` and reload server.
  All exception which will be rescued will be inserted into `ERROR_LOG`

## Setup own logger
  To create new logger you need instantiate `AuditLogger::Audit`
  First argument is name of the logger file.

    ::CATEGORY_LOG = AuditLogger::Audit.new("#{log_path_with_env}_category.log")
  Also if you want, you can insert `File::NULL` or `STDOUT` as first argument for sent output into `/dev/null/` or into console accordingly.

  Additional arguments in initialization:

    # by default
    # THREAD TBD!
    timestamp: true
    thread: true
    pid: false
    severity: false

  This option influence on otput which will be showed in the log file.


## Example of usage:
  Lets add product logger into `config/initializers/audit.rb` and enable all parametrs:

    ::PRODUCT_LOG = Audit::AuditLogger.new("#{log_path_with_env}_product.log", timestamp: true, pid: true, severity: true)

  and use logger inside the rake task: `lib/tasks/products.rake`

    namespace :products do
      desc '...'

      task :do_something => :environment do
        PRODUCT_LOG.audit 'This is rake task' do
          # Do something
          PRODUCT_LOG.info 'Output some information'
        end
      end
    end

  lets run it `rake products:do_something`

  Logger output:

    # log/audit/development_product.log
    [ 2015-05-22 10:55:35 | INFO | pid: 81767 | <start_of>: This is rake task ]
    [ 2015-05-22 10:55:35 | INFO | pid: 81767 | Output some information ]
    [ 2015-05-22 10:55:35 | INFO | pid: 81767 | </end_of>: This is rake task ]


## Error Handling:
  Method audit can accept second argument: `log_exception_only`

    PRODUCT_LOG.audit 'This is rake task', log_exception_only: true do # ( log_exception_only = false by default. )

  When you run rake task with that option, you does not see any logging at all.
  But lets add some exception into our rake task:

    class NotOurError < ::StandardError; end
    namespace :products do
      desc '...'

      task :do_something => :environment do
        PRODUCT_LOG.audit 'This is rake task', log_exception_only: true do
          # Do something
          begin
            raise NotOurError, "Error A"
          rescue => error
            raise "Error B"
          end

          PRODUCT_LOG.info 'Output some information'
        end
      end
    end

  relaunch rake task and you will see next log:

    # log/audit/development_product.log
    [ 2015-05-22 11:05:08 | INFO | pid: 83296 | <start_of>: This is rake task ]
    [ 2015-05-22 11:05:08 | ERROR | pid: 83296 | ERROR OCCURRED. See details in the Error Log. ]
    [ 2015-05-22 11:05:08 | INFO | pid: 83296 | </end_of>: This is rake task ]

    # log/audit/development_error.log
    [ 2015-05-22 11:05:08 | <start_of>: This is rake task // development_product.log ]
    [ 2015-05-22 11:05:08 | RuntimeError: Error B. Cause exception: ]
    [ 2015-05-22 11:05:08 | NotOurError: Error A. Call stack: ]
    <!-- REPRODUCE WITH GEM! -->
    <!-- TBD! -->
    [ 2015-05-22 11:05:08 | </end_of>: This is rake task // development_product.log ]

## Exception resque:
  When you launch your rake task which cause exception you always got exception and stop running of the code.

  With next option exception will be intercepted and logged but not raised on the top:

    PRODUCT_LOG.audit 'This is rake task', do_raise: false do

  If you set `do_raise` option into `false` state you will have same log as in previous example ( fully logged ),
  but in terminal output you will see nothin. This option needed when you iterate something and don't want to stop full loop if one case fall with exception

  Also you can use `LOGGER#audit_with_resque` method for such purpose instead of `LOGGER#audit`.

    PRODUCT_LOG.audit_with_resque 'This is rake task' do

## Nested usage:
  You can use logger in nested way for more deeper detalisation:

    ```ruby
      PRODUCT_LOG.audit_with_resque "#{@user.id} #{@user.name}" do
        @user.posts.each do |post|
          PRODUCT_LOG.audit "#{post.id} #{user.name}' do
            # do something.
          end
        end
      end
    ```

## ActiveRecord exceptions:
  TBD!

## Contributing

1. Fork it ( https://github.com/[my-github-username]/audit_logger/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
