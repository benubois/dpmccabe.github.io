---
layout: post
title:  "Recurring subscriptions with Ruby, RSpec and modular arithmetic"
date:   2014-01-09 16:19:50
github: https://github.com/dpmccabe/subscriptions-with-ruby
---

Whether you're developing the latest offering in the monthly subscription box space or simply adding a recurring subscription option to your e-commerce platform, you'll likely find that figuring out how to model subscriptions isn't the most obvious thing. Well, it's not obvious unless you've come across modular arithmetic in a discrete mathematics or CS course.

### A typical use case

Say you're launching a fruit delivery business where a customer can sign up for recurring shipment of (hopefully) fresh fruit at an interval of their choice.

A new customer signing up on January 1 wishing to receive a shipment of fruit every 14 days will need their subscription processed on January 1, January 15, January 29, February 12, and so on. Another customer visiting your site on January 5 might opt for a less frequent delivery of every 30 days and will need their subscription processed on January 5, February 4, March 6, and so on.

### So, how does we represent this information programmatically?

An inexperienced developer might think: "I know&hellip;I'll generate a hundred years of processing dates (just to be safe) and store them in my database."

Obviously, this solution is less than ideal and ignores the fact that there are simple mathematical concepts underlying this system. Recognizing these concepts when coding will make it easier to do things like:

* determine which subscriptions should be processed on a given date
* display the next _n_ dates a subscription should be processed
* allow a customer to change their subscription's frequency or processing date

<!-- more -->

### Your business's first few weeks of customers

Consider only customers who want fruit deliveries every 7 days. Anyone who signs up for weekly deliveries on Wednesday, January 1, 2014 will be in **Group 0** and they'll have their subscriptions processed on all future Wednesdays. Fruit connoisseurs who sign up on Thursday, January 2 will be in **Group 1** and will have their subscriptions processed on all future Thursdays. Filling in the rest of the week:

<table>
  <tr><th>Signup day</th><th>Group</th></tr>
  <tr><td>January 1 (Wednesday)</td><td>0</td></tr>
  <tr><td>January 2 (Thursday)</td><td>1</td></tr>
  <tr><td>January 3 (Friday)</td><td>2</td></tr>
  <tr><td>January 4 (Saturday)</td><td>3</td></tr>
  <tr><td>January 5 (Sunday)</td><td>4</td></tr>
  <tr><td>January 6 (Monday)</td><td>5</td></tr>
  <tr><td>January 7 (Tuesday)</td><td>6</td></tr>
</table>

On January 8, we'll process the subscriptions for **Group 0** as expected, but we'll also get some new customers. Since those new January 8 signups will also have all subsequent subscriptions processed on Wednesdays, we'll put them in **Group 0** as well. Similarly, January 9 signups belong in **Group 1**.

You can now see that as the weeks and months progress, new customers for each subsequent day will cycle through **Groups 0-6** in order. This **0, 1, 2, 3, 4, 5, 6** cycle bears resemblance to the sequence of numbers on a face of a clock, which is why <a href="http://en.wikipedia.org/wiki/Modular_arithmetic" target="_blank">modular arithmetic</a>, as this system is known, is sometimes referred to as "clock arithmetic".

### There's some kind of residue all over my code

If we launched our site on January 1, which group does a customer signing up for a weekly subscription on February 10 belong to? The cyclic nature of modular arithmetic can also be described using division and remainders. Let's improve our earlier table:

<table>
  <tr><th>Signup day</th><th>Group</th><th>Days since January 1 = <em>d</em></th><th><em>d</em> (mod 7)</th></tr>
  <tr><td>January 1 (Wednesday)</td><td>0</td><td>0</td><td>0</td></tr>
  <tr><td>January 2 (Thursday)</td><td>1</td><td>1</td><td>1</td></tr>
  <tr><td>January 3 (Friday)</td><td>2</td><td>2</td><td>2</td></tr>
  <tr><td>January 4 (Saturday)</td><td>3</td><td>3</td><td>3</td></tr>
  <tr><td>January 5 (Sunday)</td><td>4</td><td>4</td><td>4</td></tr>
  <tr><td>January 6 (Monday)</td><td>5</td><td>5</td><td>5</td></tr>
  <tr><td>January 7 (Tuesday)</td><td>6</td><td>6</td><td>6</td></tr>
  <tr><td>January 8 (Wednesday)</td><td>0</td><td>7</td><td>0</td></tr>
  <tr><td>January 9 (Thursday)</td><td>1</td><td>8</td><td>1</td></tr>
  <tr><td>January 10 (Friday)</td><td>2</td><td>9</td><td>2</td></tr>
</table>

We can see that <em>d</em> (mod 7) (the remainder of <em>d</em> &div; 7) is the calculation needed to generate the group. Since February 10 is 40 days after January 1 and 40 (mod 7) = 5, customers signing up on that day are in **Group 5**.

Put another way, all customers in **Group 5**, regardless of which Sunday they signed up on, are members of same <a href="http://mathworld.wolfram.com/ResidueClass.html" target="_blank">residue class</a> (modulo 7).

We can also determine whether a subscription will be processed on some future date if that date's residue is equal to the residue of that subscription. On June 8, 2014 (158 days since January 1), we will need to process **Group 4** since 158 (mod 7) = 4.

Keep in mind that we chose 7 for the interval in the previous example for simplicity's sake, but our code needs to work for any interval and any signup date.

### Coding the Ruby class

We'll start with a plain Ruby class, but include ActiveSupport Core Extensions for their useful date features and `cattr_reader`.

{% highlight ruby %}
require 'active_support/core_ext'

class Subscription
  cattr_reader :beginning
  attr_accessor :interval, :start_date
  attr_reader :residue

  @@beginning = Date.new(2014, 1, 1)

  def initialize(args)
    args.each { |k, v| instance_variable_set("@#{k}", v) unless v.nil? }
  end
end
{% endhighlight %}

In case you've never seen it, this is boilerplate Ruby code to initialize instance variables and declare attribute access. We can now create instances of our Subscription class like so:

{% highlight ruby %}
Subscription.new(interval: 14, start_date: Date.new(2014, 2, 10))
# => #<Subscription:0x007fb8e79f38d0 @interval=14, @start_date=Mon, 10 Feb 2014>
{% endhighlight %}

Note that we'll need the class instance variable `@@beginning` to represent "Day 0" in our system. Choosing any date in the past makes sense for our purposes, but we need some fixed reference point to calculate the residues.

### Help needed

To make our RSpec a bit cleaner, we'll write a few helper methods first.

{% highlight ruby %}
module SubscriptionSpecHelpers
  def residues(subscriptions)
    subscriptions.map(&:residue)
  end

  def unique_residues(subscriptions)
    subscriptions.map(&:residue).uniq
  end

  def beginning # 2014-01-01 in our example
    Subscription.beginning
  end
end
{% endhighlight %}

### Testing residue calculation

The first thing we'll want to test is calculating the residue for a new subscription, given some interval and start date. Let's write the test first.

{% highlight ruby %}
it 'computes members of the residue class 0' do
  subscriptions = [
    Subscription.new(interval: 7, start_date: beginning),
    Subscription.new(interval: 7, start_date: beginning + 7.days),
    Subscription.new(interval: 7, start_date: beginning + 70.days)
  ]

  expect(unique_residues(subscriptions)).to eq([0])
end
{% endhighlight %}

So, we expect that a customer who creates a weekly subscription on January 1, 2014 (our "beginning") would have residue = 0. Subscriptions created 7 or 70 days later should also have residue = 0.

It's not really possible to test every future starting date for a weekly subscription, but lets just write a few more tests to make sure we're calculating a few residues correctly.

{% highlight ruby %}
it 'computes members of the residue class 1' do
  subscriptions = [
    Subscription.new(interval: 7, start_date: beginning + 1.day),
    Subscription.new(interval: 7, start_date: beginning + 8.days),
    Subscription.new(interval: 7, start_date: beginning + 71.days)
  ]

  expect(unique_residues(subscriptions)).to eq([1])
end

it 'computes members of all possible residue classes' do
  subscriptions = [
    Subscription.new(interval: 7, start_date: beginning),
    Subscription.new(interval: 7, start_date: beginning + 1.day),
    Subscription.new(interval: 7, start_date: beginning + 2.days),
    Subscription.new(interval: 7, start_date: beginning + 3.days),
    Subscription.new(interval: 7, start_date: beginning + 4.days),
    Subscription.new(interval: 7, start_date: beginning + 5.days),
    Subscription.new(interval: 7, start_date: beginning + 6.days),
    Subscription.new(interval: 7, start_date: beginning + 7.days)
  ]

  expect(residues(subscriptions)).to eq([0, 1, 2, 3, 4, 5, 6, 0])
end
{% endhighlight %}

Here, we're confirming that our **Group 1** (residue = 1) is constructed correctly for a few different start dates and that our first 7 days of signups are correctly cycled into the right group.

### Getting our residue tests to pass

First, we'll need a utility method to compute the residue for a provided date.

{% highlight ruby %}
def residue_for_date(date)
  (date - @@beginning).to_i.modulo(@interval)
end
{% endhighlight %}

This method is provided a date, calculates the number of days since `@@beginning`, and returns the residue thanks to Ruby's helpful `modulo` method. You can also use the more familiar `%` operator if you prefer.

Next, let's automatically compute the residue when a `Subscription` is initialized and store it in the `@residue` instance variable.

{% highlight ruby %}
def initialize(args)
  args.each { |k, v| instance_variable_set("@#{k}", v) unless v.nil? }
  compute_residue
end

private

def residue_for_date(date)
  (date - @@beginning).to_i.modulo(@interval)
end

def compute_residue
  @residue = residue_for_date(@start_date)
end
{% endhighlight %}

Now our tests above will pass.

### Should I process the subscription on some date?

The other key feature left to implement is a method that lets us determine if a certain subscription should be processed on a given date or not. Again, we'll write the tests first.

Just to mix things up, we'll consider a customer buying a subscription on January 12, 2014 and preferring a fruit delivery every 30 days. We want our `process_on?` method to return `true` on that day and 30 days later, but `false` 29 days later, for instance.

{% highlight ruby %}
context 'when the subscription is every 30 days and starts 11 days after the beginning' do
  let(:subscription) { Subscription.new(interval: 30, start_date: beginning + 11.days) }

  it 'processes it on its start date' do
    expect(subscription.process_on?(beginning + 11.days)).to be_true
  end

  it 'processes it on its next processing date' do
    expect(subscription.process_on?(beginning + 11.days + 30.days)).to be_true
  end

  it 'does not process it on the day before its next processing date' do
    expect(subscription.process_on?(beginning + 11.days + 29.days)).to be_false
  end
end
{% endhighlight %}

To write this method, our work is cut out for us.

{% highlight ruby %}
def process_on?(date)
  residue_for_date(date) == @residue
end
{% endhighlight %}

The new tests pass. Now, remember that on some day in the future, we'll probably be processing subscriptions for customers who specified different intervals. For example, a subscription created on January 1 with an interval of 10 days will be processed on January 31, but so will a subscription created on January 11 with an interval of 20 days. Let's write a test for that situation just to be sure.

{% highlight ruby %}
it 'should process subscriptions of different intervals on the same day when applicable' do
  subscription_1 = Subscription.new(interval: 10, start_date: beginning)
  subscription_2 = Subscription.new(interval: 8, start_date: beginning + 2.days)
  subscription_3 = Subscription.new(interval: 15, start_date: beginning + 5.days)
  subscription_4 = Subscription.new(interval: 10, start_date: beginning + 5.days)

  common_date = Date.new(2014, 2, 20)

  expect(subscription_1.process_on?(common_date)).to be_true
  expect(subscription_2.process_on?(common_date)).to be_true
  expect(subscription_3.process_on?(common_date)).to be_true
  expect(subscription_4.process_on?(common_date)).to be_false
end
{% endhighlight %}

Sure enough, our collection of miscellaneous subscriptions with different intervals and start dates will get processed on the same day when applicable.

### Next processing date

It would certainly be useful to know the next date a subscription will be processed on, both for internal use and, perhaps, to display to the customer in their account information.

Thankfully, this is also a simple calculation. For a subscription starting on March 19 and an interval of 21 days, we know by counting days that our next processing dates will be April 9 and April 30. How would we calculate this? Naturally, the answer has something to do with residues again.

Our example subscription has residue = 14 and we'll call this value _sr_. Let's consider some example dates and compare the residues of these days with our subscription's residue.

<table>
  <tr><th>Date</th><th>Residue = <em>dr</em></th><th><em>sr</em> - <em>dr</em></th><th>(<em>sr</em> - <em>dr</em>) (mod 21) = <em>m</em></th><th>Date + <em>m</em>.days</th></tr>
  <tr><td>March 19</td><td>14</td><td>0</td><td>0</td><td>March 19</td></tr>
  <tr><td>March 20</td><td>15</td><td>-1</td><td>20</td><td>April 9</td></tr>
  <tr><td>March 21</td><td>16</td><td>-2</td><td>19</td><td>April 9</td></tr>
  <tr><td>March 24</td><td>19</td><td>-5</td><td>16</td><td>April 9</td></tr>
  <tr><td>April 2</td><td>7</td><td>7</td><td>7</td><td>April 9</td></tr>
  <tr><td>April 8</td><td>13</td><td>1</td><td>1</td><td>April 9</td></tr>
  <tr><td>April 9</td><td>14</td><td>0</td><td>0</td><td>April 9</td></tr>
  <tr><td>April 10</td><td>15</td><td>-1</td><td>20</td><td>April 30</td></tr>
</table>

Now the pattern is becoming clear. We know that on any given date, it's either the day we're processing this subscription or it's at most 20 days away from the next processing date. The difference in residues gives us the number of days we need to move forward to reach the next processing date. However, when <em>sr</em> - <em>dr</em> is negative, we'd actually be moving back in time to the previous processing date, so we should advance (21 - (<em>sr</em> - <em>dr</em>)) days into the future. Calculating <em>sr</em> - <em>dr</em> (mod 21) gives us the correct number of days into the future regardless of the sign of <em>sr</em> - <em>dr</em>.

The spec and code follows as such.

{% highlight ruby %}
context 'when the subscription is every 10 days and starts 4 days after the beginning' do
  let(:subscription) { Subscription.new(interval: 10, start_date: beginning + 4.days) }

  it 'calculates the first processing date' do
    expect(subscription.next_processing_date(beginning + 4.days)).to eq(beginning + 4.days)
  end

  it 'calculates the next processing date 1 day later' do
    expect(subscription.next_processing_date(beginning + 4.days + 1.day)).to eq(beginning + 14.days)
  end

  it 'calculates the next processing date 10 days later' do
    expect(subscription.next_processing_date(beginning + 4.days + 10.days)).to eq(beginning + 14.days)
  end

  it 'calculates the third processing date 17 days later' do
    expect(subscription.next_processing_date(beginning + 4.days + 17.days)).to eq(beginning + 24.days)
  end
{% endhighlight %}

The code that passes these tests is another simple one-liner.

{% highlight ruby %}
def next_processing_date(from_date)
  from_date + ((@residue - residue_for_date(from_date)).modulo(@interval)).days
end
{% endhighlight %}

Our `next_processing_date` method also makes it easy to fetch any number of future processing dates.

{% highlight ruby %}
def next_n_processing_dates(n, from_date)
  first_next_processing_date = next_processing_date(from_date)
  0.upto(n - 1).map { |i| first_next_processing_date + (@interval * i).days }
end
{% endhighlight %}

### Using recurring subscriptions in a real project

If you're reading this, you're probably using some combination of a Ruby framework, ORM, and database. Integrating this `Subscription` class is simple a matter of persisting the `interval` and `residue` attributes in your `Subscription` record (after validating them) along with whatever other information you're storing per subscription.

Given the popularity of monthly "subscription box" services in recent years&mdash;I've built a few, myself&mdash;you might be more inclined to process your subscriptions on a monthly basis, rather than daily. Surely, you could process a monthly subscription every 30 days, but anyone who's looked at a calendar recently knows that's not quite the same thing.

The GitHub repo, <a href="https://github.com/dpmccabe/subscriptions-with-ruby" taret="_blank">subscriptions-with-ruby</a>, offers some modifications to this `Class` that enable monthly subscriptions, in addition to a more robust test suite.
