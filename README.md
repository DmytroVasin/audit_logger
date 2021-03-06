# AuditLogger

This gem implements simple and separated Rails Logger for any action that you want.
If you want separated logger files for email notification, data import, migration, ets. this gem - is what you need.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'audit_logger'
```

And then execute:

    $ bundle

After running bundle install, run the generator:

    $ rails generate audit_logger:install

## Usage
  The installer creates `config/initializers/audit.rb` file which implement dummy setup of audit logger.

  ```ruby
unless Rails.env.test?
  ::ERROR_LOG = AuditLogger::Audit.new('error', timestamp: true, pid: true, severity: true, thread: true)

  # ::AUDIT_NULL   = AuditLogger::Audit.new(File::NULL)
  # ::AUDIT_STDOUT = AuditLogger::Audit.new(STDOUT)
  # ::PRODUCT_LOG  = AuditLogger::Audit.new('product')
end
  ```

  By default all files will be generated in `#{Rails.root}/log/audit/development` folder ( because `development` is default `Rails.env` ).

  If you want to change folder name you should redefine `AuditLogger::Audit#folder_name` method.
  All exception which will be rescued will be inserted into `ERROR_LOG`.

## Setup own logger
  To create new logger you need instantiate `AuditLogger::Audit`
  First argument is name of the logger file.

  ```ruby
::PRODUCT_LOG  = AuditLogger::Audit.new('product')
  ```
  Also if you want, you can insert `File::NULL` or `STDOUT` as first argument for sent output into `/dev/null/` or into console accordingly.

  Additional arguments of initialization:

  ```ruby
options_hash = {timestamp: true, thread: false, pid: false, severity: false}
::PRODUCT_LOG = AuditLogger::Audit.new('#{file_path}', options_hash)
  ```

  where:

    timestamp: true - by default, options which shows date and time
    severity: false - by default, options which shows severity ( +WARN+, +ERROR+, +FATAL+, or +UNKNOWN+ )
    pid: false - by default, options which shows PID of a proces +$$+
    thread: false - by default, options which shows Thread.current.object_id

  This option influence on otput which will be showed in the log file.


## Example of usage:
  Lets add products logger into `config/initializers/audit.rb` and enable all available parametrs:

  ```ruby
::PRODUCT_LOG = AuditLogger::Audit.new('product', timestamp: true, pid: true, severity: true, thread: true)
  ```

  and use logger inside the rake task: `lib/tasks/products.rake`

  ```ruby
namespace :products do
  desc 'Do something'

  task :do_something => :environment do
    PRODUCT_LOG.audit 'This is rake task' do
      # Do something
      PRODUCT_LOG.info 'Output some information'
    end
  end
end
  ```

  lets run it `rake products:do_something`

  Logger output:

    # log/audit/development/product.log
    [ 2015-05-25 15:05:07 | INFO | pid: 3443 | thread: 70101873590780 | <start_of>: This is rake task ]
    [ 2015-05-25 15:05:07 | INFO | pid: 3443 | thread: 70101873590780 | Output some information ]
    [ 2015-05-25 15:05:07 | INFO | pid: 3443 | thread: 70101873590780 | </end_of>: This is rake task ]


  You can use this logger in migrations, models, ets:

  ```ruby
class AddAdditionalFieldsToUser < ActiveRecord::Migration
  def up
    DB_MIGRATION_LOG.log_block "#{self.class.name}: create some additional fields" do
  ```

  ```ruby
def replace_active_cart(current_cart)
  if self.cart.present?
    PAYMENT_LOG.info "Cart assigned to Order##{self.cart.order.id}. Current cart##{current_cart.id}"
      # do something
  ```

## Error Handling:
  Method audit can accept second argument: `log_exception_only`

  ```ruby
# log_exception_only: false by default.
PRODUCT_LOG.audit 'This is rake task', log_exception_only: true do
  ```

  When you run rake task with that option, you does not see any logging at all.
  But lets add some exception into our rake task:

  ```ruby
class NotOurError < ::StandardError; end
namespace :products do
  desc 'Do something'

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
  ```

  relaunch rake task and you will see next log:

    # log/audit/development/product.log
    [ 2015-05-25 15:06:45 | INFO | pid: 3710 | thread: 70177429783040 | <start_of>: This is rake task ]
    [ 2015-05-25 15:06:45 | ERROR | pid: 3710 | thread: 70177429783040 | ERROR OCCURRED. See details in the Error Log. ]
    [ 2015-05-25 15:06:45 | INFO | pid: 3710 | thread: 70177429783040 | </end_of>: This is rake task ]

    # log/audit/development/error.log
    [ 2015-05-25 15:06:45 | INFO | pid: 3710 | thread: 70177429783040 | <start_of>: This is rake task // product.log ]
    [ 2015-05-25 15:06:45 | ERROR | pid: 3710 | thread: 70177429783040 | RuntimeError: Error B. Cause exception: ]
    [ 2015-05-25 15:06:45 | ERROR | pid: 3710 | thread: 70177429783040 | NotOurError: Error A. Call stack: ]
    [ 2015-05-25 15:06:45 | ERROR | pid: 3710 | thread: 70177429783040 | -> ../lib/tasks/products.rake:44:in `block (3 levels) in <top (required)>' ]
    [ 2015-05-25 15:06:45 | ERROR | pid: 3710 | thread: 70177429783040 | -> ../lib/tasks/products.rake:41:in `block (2 levels) in <top (required)>' ]
    [ 2015-05-25 15:06:45 | INFO | pid: 3710 | thread: 70177429783040 | </end_of>: This is rake task // product.log ]


## Exception resque:
  When you launch your rake task which cause exception you always got exception and stop running of the code.

  With next option exception will be intercepted and logged but not raised on the top:

  ```ruby
PRODUCT_LOG.audit 'This is rake task', do_raise: false do
  ```

  If you set `do_raise` option into `false` state you will have same log as in previous example ( fully logged ),
  but in terminal output you will see nothin. This option is needed when you iterate something and don't want to stop full loop if one case fail with exception

  Also you can use `LOGGER#audit_with_resque` method for such purpose instead of `LOGGER#audit`.

  ```ruby
PRODUCT_LOG.audit_with_resque 'This is rake task' do
  ```

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
  Lets see how the gem works with AR.

  Add some constraints into DB:

  ```ruby
create_table "products" do |t|
  t.string   "title", default: "", null: false
  ```

  And create some additional rake task:

  ```ruby
namespace :products do
  desc 'Do something'
  task :create_product => :environment do
    PRODUCT_LOG.audit_with_resque 'Product creation' do
      Product.create!
    end
  end
end
  ```

  relaunch rake task and you will see next log:

    # log/audit/development/product.log
    [ 2015-05-25 15:17:00 | INFO | pid: 6013 | thread: 70285626049020 | <start_of>: Product creation ]
    [ 2015-05-25 15:17:00 | ERROR | pid: 6013 | thread: 70285626049020 | ERROR OCCURRED. See details in the Error Log. ]
    [ 2015-05-25 15:17:00 | INFO | pid: 6013 | thread: 70285626049020 | </end_of>: Product creation ]

    # log/audit/development/error.log
    [ 2015-05-25 15:17:00 | INFO | pid: 6013 | thread: 70285626049020 | <start_of>: Product creation // product.log ]
    [ 2015-05-25 15:17:00 | ERROR | pid: 6013 | thread: 70285626049020 | ActiveRecord::StatementInvalid: PG::NotNullViolation: ERROR: null value in column "title" violates not-null constraint DETAIL: Failing row contains (1, null, 2015-05-25 12:17:00.852781, 2015-05-25 12:17:00.852781, null). : INSERT INTO "products" ("created_at", "updated_at") VALUES ($1, $2) RETURNING "id". Cause exception: ]
    [ 2015-05-25 15:17:00 | ERROR | pid: 6013 | thread: 70285626049020 | PG::NotNullViolation: ERROR: null value in column "title" violates not-null constraint DETAIL: Failing row contains (1, null, 2015-05-25 12:17:00.852781, 2015-05-25 12:17:00.852781, null).. Call stack: ]
    [ 2015-05-25 15:17:00 | ERROR | pid: 6013 | thread: 70285626049020 | -> ../lib/tasks/products.rake:77:in `block (3 levels) in <top (required)>' ]
    [ 2015-05-25 15:17:00 | ERROR | pid: 6013 | thread: 70285626049020 | -> ../lib/tasks/products.rake:75:in `block (2 levels) in <top (required)>' ]
    [ 2015-05-25 15:17:00 | INFO | pid: 6013 | thread: 70285626049020 | </end_of>: Product creation // product.log ]

  What about walidation errors?
  Lets add some validation on to `Product` model:

  ```ruby
class Product < ActiveRecord::Base
  validates :title, length: { minimum: 50 }
end
  ```

  And change `Product.create!` to `Product.create!(title: 'Small title')` and relaunch the rake task.
  `log/audit/development/product.log` will be the same as previous, but `error.log` will have more detailed information about error exception:

    # log/audit/development/error.log
    [ 2015-05-25 15:19:58 | INFO | pid: 6729 | thread: 70207020597760 | <start_of>: Product creation // product.log ]
    [ 2015-05-25 15:19:58 | ERROR | pid: 6729 | thread: 70207020597760 | ActiveRecord::RecordInvalid: Validation failed: Title is too short (minimum is 50 characters). Call stack: ]
    [ 2015-05-25 15:19:58 | ERROR | pid: 6729 | thread: 70207020597760 | -> ../lib/tasks/products.rake:77:in `block (3 levels) in <top (required)>' ]
    [ 2015-05-25 15:19:58 | ERROR | pid: 6729 | thread: 70207020597760 | -> ../lib/tasks/products.rake:75:in `block (2 levels) in <top (required)>' ]
    [ 2015-05-25 15:19:58 | INFO | pid: 6729 | thread: 70207020597760 | </end_of>: Product creation // product.log ]

## Contributing

1. Fork it ( https://github.com/DmytroVasin/audit_logger/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
