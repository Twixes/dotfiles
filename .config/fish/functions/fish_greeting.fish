function fish_greeting
    set -l cache_dir ~/.cache/fish
    set -l wttr_report_path {$cache_dir}/weather
    set -l wttr_options '?0Q'
    mkdir -p $cache_dir
    if not test -e $wttr_report_path
    or test (find $wttr_report_path -mmin +60)
        echo > {$wttr_report_path}_temp
        curl -sm 2 --compressed "https://wttr.in/$wttr_options" >> {$wttr_report_path}_temp
        test $status -eq 0
        and mv -f {$wttr_report_path}_temp $wttr_report_path
    end
    if test -e $wttr_report_path
        cat $wttr_report_path
    else
        echo "Couldn't fetch weather data. Is wttr.in available?"
    end
end
