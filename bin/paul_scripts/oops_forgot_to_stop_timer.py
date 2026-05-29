#!/usr/bin/env python3
"""
Calculate the actual time remaining on a forgotten timer.

This script determines what the timer reading should have been at the intended
stop time by subtracting the "extra" running time (the duration it ran after
it should have stopped) from the current reading found on the timer.

Input Semantics:
    - timer_reading: The value currently displayed on the forgotten timer (e.g., "69:25").
    - time_actually_left: The timestamp when you SHOULD have stopped the timer (but forgot).
    - timer_stopped: The timestamp when you DID stop the timer (defaults to current time).

Output Format:
    - HH:MM (or "00:00" if the calculated time is negative/expired).
"""

import datetime
import click


DAY_LIST = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']


def parse_time_delta(time_str: str) -> datetime.timedelta:
    """Parse a time string in HH:MM format into a timedelta.

    Supports durations greater than 24 hours (e.g., '69:00' for 69 hours).

    Args:
        time_str: A string representing a time duration in HH:MM format
            (e.g., '69:25' for 69 hours and 25 minutes).

    Returns:
        A datetime.timedelta object representing the parsed duration.

    Raises:
        ValueError: If the time string is not in HH:MM format or contains
            negative components.
        click.BadParameter: If the time format is invalid (wraps ValueError
            for click CLI error handling).
    """
    try:
        parts = time_str.split(':')
        if len(parts) != 2:
            raise ValueError("Time must be in HH:MM format")

        hours, minutes = int(parts[0]), int(parts[1])

        if hours < 0 or minutes < 0:
            raise ValueError("Time components cannot be negative")

        return datetime.timedelta(hours=hours, minutes=minutes)
    except (ValueError, IndexError) as e:
        raise click.BadParameter(f"Invalid time format: '{time_str}'. Use HH:MM (e.g., '69:25').")


def parse_datetime(dt_str: str) -> datetime.datetime:
    """Parse a datetime string using dateparser for natural language support.

    Supports the following input formats:
    - YYYY-MM-DD HH:MM:SS (absolute format)
    - Natural language like "yesterday 3pm", "2 hours ago"
    - "last [day of week]" (e.g., "last friday")
    - "last [day of week], [time]" (e.g., "last friday, 8pm")

    Args:
        dt_str: A string representing a datetime. Can be an absolute datetime
            in YYYY-MM-DD HH:MM:SS format, natural language expressions like
            "yesterday 3pm" or "2 hours ago", or day references like "last
            friday" or "last friday, 8pm".

    Returns:
        A datetime.datetime object representing the parsed datetime.

    Raises:
        ValueError: If the datetime string cannot be parsed.
        click.BadParameter: If the time part of a "last [day], [time]" pattern
            cannot be parsed in context.
        click.ClickException: If the dateparser library is not installed.
    """
    import re
    import dateparser

    # Handle "last [day of week], [time]" pattern
    day_time_match = re.match(
        rf'^last\s+({"|".join(DAY_LIST)}),?\s*(.+)$',
        dt_str,
        re.IGNORECASE
    )
    if day_time_match:
        click.echo("WARNING: Don't have to specify \"last\" when specifying day "
                   "of week. You can just say \"friday, 8pm\"")
        target_day = DAY_LIST.index(
            day_time_match.group(1).lower()
        )
        time_str = day_time_match.group(2).strip()

        # Get base date (last occurrence of target day)
        current_day = datetime.datetime.now().weekday()
        days_ago = (current_day - target_day) % 7
        if days_ago == 0:
            days_ago = 7  # If today is the target day, go back a full week
        base_date = datetime.datetime.now() - datetime.timedelta(days=days_ago)

        # Parse the time part (e.g., "8pm", "14:30")
        time_result = dateparser.parse(time_str, settings={'RELATIVE_BASE': base_date})
        if time_result is None:
            raise click.BadParameter(f"Could not parse time '{time_str}' in context of '{dt_str}'")

        # Combine date and time
        return base_date.replace(
            hour=time_result.hour,
            minute=time_result.minute,
            second=time_result.second,
            microsecond=time_result.microsecond
        )

    # Handle "last [day of week]" alone
    day_only_match = re.match(
        rf'^last\s+({"|".join(DAY_LIST)})$',
        dt_str,
        re.IGNORECASE
    )
    if day_only_match:
        target_day = DAY_LIST.index(
            day_only_match.group(1).lower()
        )
        current_day = datetime.datetime.now().weekday()
        days_ago = (current_day - target_day) % 7
        if days_ago == 0:
            days_ago = 7
        return (datetime.datetime.now() - datetime.timedelta(days=days_ago)).replace(
            hour=0, minute=0, second=0, microsecond=0
        )

    # Try dateparser for everything else
    try:
        result = dateparser.parse(
            dt_str,
            settings={
                'PREFER_DATES_FROM': 'past',
                'RELATIVE_BASE': datetime.datetime.now()
            }
        )
        if result is None:
            raise ValueError(f"Could not parse datetime string: '{dt_str}'")
        return result
    except ImportError:
        raise click.ClickException(
            "dateparser library is required but not installed. "
            "Install it with: pip install dateparser"
        )


def format_to_hours_minutes(td: datetime.timedelta) -> str:
    """Format a timedelta into HH:MM string representation.

    Handles durations greater than 24 hours by accumulating total hours.
    Returns '00:00' if the duration is negative or zero.

    Args:
        td: A datetime.timedelta object representing the duration to format.

    Returns:
        A string in HH:MM format representing the duration. Returns '00:00'
        if the input timedelta is negative or zero.
    """
    if td <= datetime.timedelta(0):
        return "00:00"

    total_seconds = int(td.total_seconds())
    total_minutes = total_seconds // 60

    # Calculate hours and minutes from total minutes
    hours = total_minutes // 60
    minutes = total_minutes % 60

    return f"{hours}:{minutes:02d}"


@click.command()
@click.help_option('-h', '--help')
@click.argument('timer_reading', type=str, required=True,
                callback=lambda ctx, param, value: parse_time_delta(value))
@click.option('--should-have-stopped', '-l', type=str, required=True,
              help='The timestamp when you SHOULD have stopped the timer (supports natural language like "last friday, 8pm", "yesterday 3pm", "2 hours ago")')
@click.option('--actually-stopped', '-t', type=str, default=None,
              help='The timestamp when you actually discovered and stopped the timer. Defaults to current time.')
def main(timer_reading, should_have_stopped, actually_stopped):
    """Calculate the actual time remaining on a forgotten timer.

    \b
    SCENARIO:
        You left a timer running longer than intended and you know when you left
        on the day the timer was accidentally left running.

    The currently displayed (too large) timer value should be given as
    "timer_reading".
    As mentioned, you need to know what the reading would have been at the
    (rough) moment you should have stopped it, which should be entered as as the
    "--should-have-stopped" option.
    If you're stopped the timer at some other point than "now", enter that time
    in the "--actually-stopped" option.

    \b
    INPUTS:
        timer_reading:   The value on the timer when stopped (e.g., "69:25").
        --should-have-stopped (-l): The time you were supposed to stop (supports
                                    "most" natural language).
        --actually-stopped (-t): The time you actually stopped it (default: now).

    \b
    OUTPUT:
        HH:MM format representing the calculated "Actual Time Left".
    """
    # Parse intended stop time
    should_stop_dt = parse_datetime(should_have_stopped)

    # Parse actual stop time or default to now
    if actually_stopped:
        actual_stop_dt = parse_datetime(actually_stopped)
    else:
        actual_stop_dt = datetime.datetime.now()

    # Validation: Ensure logical order of events
    if actual_stop_dt < should_stop_dt:
        raise click.ClickException(
            f"Error: 'Actually Stopped' ({actual_stop_dt}) cannot be before 'Should Have Stopped' ({should_stop_dt}). "
            "Please ensure the timestamps are in chronological order."
        )

    # Calculate how much extra time the timer ran
    extra_time = actual_stop_dt - should_stop_dt

    # Calculate what the reading would have been at the intended stop time
    actual_delta = timer_reading - extra_time

    print(f"should_have_stopped: {should_have_stopped}")
    print(f"actual_stop_dt: {actual_stop_dt}")
    print(f"timer_reading: {timer_reading}")
    print(f"extra_time: {extra_time}")
    print(f"actual_delta: {actual_delta}")

    if actual_delta < datetime.timedelta(0):
        click.echo("Warning: The calculated time is negative. ")
        click.echo("This means the timer reading was likely lower than the 'extra' time ran,")
        click.echo("or the timer had already expired before you stopped it.")
        click.echo(f"Calculated value: {actual_delta}")
        click.echo(f"Actual Time Left: 00:00 (Timer has expired)")
    else:
        formatted_remaining = format_to_hours_minutes(actual_delta)
        click.echo(f"Actual time left: {formatted_remaining}")


if __name__ == '__main__':
    main()  # type: ignore
