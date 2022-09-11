DDBLOCALHOME=dynamodb_local_latest

warn() {
    local fmt="$1"
    shift
    printf "%s\n" "$fmt" "$@" >&2
}

die() {
    local st="$?"
    if [[ "$1" != *[^0-9]* ]]; then
        st="$1"
        shift
    fi
    warn "$@"
    # Stop ddb local
    echo 'Killing ddb local'
    ps -ef | grep DynamoDBLocal.jar | grep -v grep | awk '{print $2}' | xargs kill -9
    exit "$st"
}

# Download ddb local, if needed
if [[ ! -d $DDBLOCALHOME ]]; then
    echo 'Downloading ddb local...'
    CWD=`pwd`
    mkdir $DDBLOCALHOME
    cd $DDBLOCALHOME
    wget https://s3-us-west-2.amazonaws.com/dynamodb-local/dynamodb_local_latest.tar.gz
    tar xvzf dynamodb_local_latest.tar.gz
    cd $CWD
fi

# Start local instance of ddb local in background
echo 'Starting ddb local...'
java -Djava.library.path=./$DDBLOCALHOME/DynamoDBLocal_lib -jar ./dynamodb_local_latest/DynamoDBLocal.jar -inMemory -sharedDb -port 28588 &

# take a breath to allow startup
sleep 1

echo 'Running tests...'
AWS_ENDPOINT=localhost:28588 AWS_DEFAULT_REGION=us-local-1 AWS_ACCESS_KEY_ID=a AWS_SECRET_ACCESS_KEY=b go test -v . || die $? 'Tests failed'
