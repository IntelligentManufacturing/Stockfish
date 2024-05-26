#!/bin/bash

# Function to fetch network
fetch_network() {
    echo "Default net: $nnuenet"
    if [ -z "$curl_or_wget" ]; then
        echo "Neither curl nor wget is installed. Install one of these tools unless the net has been downloaded manually."
    fi
    if [ -z "$shasum_command" ]; then
        echo "shasum / sha256sum not found, skipping net validation."
    elif [ -f "$nnuenet" ]; then
        if [ "$nnuenet" != "nn-"$( $shasum_command "$nnuenet" | cut -c1-12 )".nnue" ]; then
            echo "Removing invalid network"
            rm -f "$nnuenet"
        fi
    fi

    for nnuedownloadurl in "$nnuedownloadurl1" "$nnuedownloadurl2"; do
        if [ -f "$nnuenet" ]; then
            echo "$nnuenet available: OK"
            break
        else
            if [ -n "$curl_or_wget" ]; then
                echo "Downloading ${nnuedownloadurl}"
                $curl_or_wget "${nnuedownloadurl}" > "$nnuenet"
            else
                echo "No net found and download not possible"
                exit 1
            fi
        fi

        if [ -n "$shasum_command" ]; then
            if [ "$nnuenet" != "nn-"$( $shasum_command "$nnuenet" | cut -c1-12 )".nnue" ]; then
                echo "Removing failed download"
                rm -f "$nnuenet"
            fi
        fi
    done

    if ! [ -f "$nnuenet" ]; then
        echo "Failed to download $nnuenet."
    fi

    if [ -n "$shasum_command" ]; then
        if [ "$nnuenet" = "nn-"$( $shasum_command "$nnuenet" | cut -c1-12 )".nnue" ]; then
            echo "Network validated"
        fi
    fi
}

# Function to set up variables for the net stuff
netvariables() {
    nnuenet=$(grep "$1" ../src/evaluate.h | grep define | sed 's/.*\(nn-[a-z0-9]\{12\}.nnue\).*/\1/')
    nnuedownloadurl1="https://tests.stockfishchess.org/api/nn/$nnuenet"
    nnuedownloadurl2="https://github.com/official-stockfish/networks/raw/master/$nnuenet"
    curl_or_wget=$(if hash curl 2>/dev/null; then echo "curl -skL"; elif hash wget 2>/dev/null; then echo "wget -qO-"; fi)
    shasum_command=$(if hash shasum 2>/dev/null; then echo "shasum -a 256"; elif hash sha256sum 2>/dev/null; then echo "sha256sum"; fi)
}

# Main execution for evaluation network (nnue)
main() {
    script_dir=$(cd $(dirname $0); pwd)
    echo "nnue dir: $script_dir"
    cd $script_dir
    netvariables "EvalFileDefaultNameBig"
    fetch_network
    netvariables "EvalFileDefaultNameSmall"
    fetch_network
}

# Run the main function
main