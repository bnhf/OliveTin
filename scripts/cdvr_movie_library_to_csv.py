"""
Author: Gildas Lefur (a.k.a. "mjitkop" in the Channels DVR forums)

Description: This script retrieves the list of movies from a Channels DVR 
library and writes it to a CSV file. Only the following attributes from 
a movie are written to the CSV file: title, release year, source, channel 
number (for recordings), and the path on the disk where the video file is.

Disclaimer: this is an unofficial script that is NOT supported by the
developers of Channels DVR.

For bug reports and support, go to: 
https://community.getchannels.com/t/python-script-cdvr-movie-list-csv-file/35491?u=mjitkop

Version History:
- 2023.03.06.1743: Initial version of the script.
"""

import argparse
import csv
import re
import requests
import sys
from datetime import datetime

CSV_FILE_NAME_EXT    = '.csv'
CSV_FILE_NAME_BASE   = 'channels_dvr_movie_list_'
DEFAULT_PORT_NUMBER  = 8089
LOOPBACK_ADDRESS     = '127.0.0.1'
PLAY_ON_FOLDER_NAME  = 'PlayOn'
SOURCE_IMPORT        = 'Import'
SOURCE_PLAY_ON_CLOUD = 'PlayOn Cloud'
SOURCE_RECORDING     = 'Recording'
SOURCE_STREAM_FILE   = 'Stream File'
SOURCE_STREAM_LINK   = 'Stream Link'
STREAM_FILE_EXT      = 'strm'
STREAM_LINK_FILE_EXT = 'strmlnk'
VERSION              = '2023.03.06.1743'
                       

##############################################################################
#                                                                            #
#                             Class definitions                              #
#                                                                            #
##############################################################################

class Movie:
    '''Attributes and methods to handle one movie from the Channels DVR
       library.
    '''
    def __init__(self, json_movie):
        '''Initialize the attributes of a movie from the given json
           input.
        '''
        self._json_movie  = json_movie
        
        self.title        = self.extract_title_from_json()
        self.release_year = self.extract_release_year_from_json()
        self.source       = self.determine_source()
        self.channel      = self.extract_channel_from_json()
        self.verified     = self._json_movie['verified']
        self.path         = self._json_movie['path']
	   
    def extract_title_from_json(self):
        '''Extract the title from the current json movie and remove the
           release year from the end of it.

           Example: "Titanic (1997)" -> "Titanic"
        '''
        library_title = self._json_movie['title']
        
        # Remove the year from the end of the string (ex: "(1997)")
        pattern = r'\s*\(\d{4}\)$'
        output_str = re.sub(pattern, '', library_title).strip()
        
        # In case the year is not in the title, remove "()" from the title.
        output_str = re.sub(r'\(\)', '', output_str)
    
        return output_str

    def extract_release_year_from_json(self):
        '''Extract the release year from the current json movie.
           
           Some movies may not have a release year that is provided.
           If this is the case, return '?'.
        '''
        return self._json_movie.get('release_year', '?')
        
    def determine_source(self):
        """
        Determine the source of the movie based on its path or metadata.

        The source is determined as follows:
        1. If the path ends with '.strmlnk', it is considered a stream link.
        2. If the path ends with '.strm', it is considered a stream file.
        3. If the path contains 'PlayOn', it is considered a PlayOn Cloud recording.
        4. If the movie metadata includes a 'channel' field, it is considered a
           recording from a DVR.
        5. Otherwise, it is considered an import.

        Returns:
            str: A string indicating the source of the movie, which will be one of
            the following values: 'Import', 'Recording', 'PlayOn Cloud',
            'Stream Link', or 'Stream File'.
        """
        source = SOURCE_IMPORT
        
        if self._json_movie['path'].endswith(STREAM_LINK_FILE_EXT):
            source = SOURCE_STREAM_LINK
            
        if self._json_movie['path'].endswith(STREAM_FILE_EXT):
            source = SOURCE_STREAM_FILE
            
        if PLAY_ON_FOLDER_NAME in self._json_movie['path']:
            source = SOURCE_PLAY_ON_CLOUD
            
        if self._json_movie.get('channel'):
            source = SOURCE_RECORDING
            
        return source
        
    def extract_channel_from_json(self):
        """
        Extract the channel number from a JSON representation of a movie.

        Returns the channel number if it exists in the JSON representation,
        otherwise returns 'n/a'.

        Returns:
            str: The channel number associated with the movie in the JSON
            representation, or 'n/a' if it is not present.

        Example usage:
            >>> movie_json = {'title': 'The Shawshank Redemption', 'year': '1994',
            'channel': '6090'}
            >>> Movie(movie_json).extract_channel_from_json()
            '6090'
        """
        return self._json_movie.get('channel', 'n/a')
    
##############################################################################
#                                                                            #
#                            Function definitions                            #
#                                                                            #
##############################################################################

def write_movie_list_to_csv_file(json_movie_list):
    """
    Given a list of dictionaries containing movie data in JSON format, write the
    information to a new CSV file with a filename generated using the create_csv_file_name
    function. The CSV file will contain rows for each movie, with the columns representing
    the keys in the JSON dictionaries.

    Args:
        json_movie_list (list): A list of dictionaries containing movie data in JSON format.

    Returns:
        None: This function does not return anything, but it writes the data to a CSV file
        and prints a message indicating where the file can be found.

    Raises:
        None: This function does not raise any exceptions, but it assumes that the
        create_csv_file_name and create_csv_rows functions are defined and working properly.
    """
    csv_file_name = create_csv_file_name()
    csv_rows_to_write = create_csv_rows(json_movie_list)
    
    with open(csv_file_name, 'w', newline='') as csv_file:
        csv_writer = csv.writer(csv_file)
        csv_writer.writerows(csv_rows_to_write)
    
    print("Movie list available in " + csv_file_name)

def create_csv_file_name():
    """
    Generate a filename for a new CSV file based on the current date and time.

    Returns:
        str: A string containing the filename with a format like
        "movies_20220305_163009.csv" (using the current date and time).
    """
    time_stamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    csv_file_name = CSV_FILE_NAME_BASE + time_stamp + CSV_FILE_NAME_EXT
    
    return csv_file_name
    
def create_csv_rows(json_movie_list):
    """
    Given a list of dictionaries containing movie data in JSON format, 
    create a list of rows for writing to a CSV file.

    Args:
        json_movie_list (list): A list of dictionaries containing 
        movie data in JSON format. Each dictionary should have the same
        keys representing the movie data.

    Returns:
        list: A list of lists, where each sublist contains the movie 
        data as strings to be written as a row to a CSV file. The first
        row contains the header with column names 'Title', 'Release 
        Year', 'Source', 'Channel', 'Verified', and 'Path'.
    """
    csv_rows = []
    header   = ['Title', 'Release Year', 'Source', 'Channel', 'Verified', 'Path']
    
    csv_rows.append(header)
    
    for json_movie in json_movie_list:
        movie = Movie(json_movie)
        csv_rows.append([movie.title, movie.release_year, movie.source, \
                         movie.channel, movie.verified, movie.path])
        
    return csv_rows
        
def get_movies_from_channels_dvr_api(server_ip_address, port_number):
    """
    Retrieve a list of movies in JSON format from a Channels DVR server API.

    Args:
        server_ip_address (str): The IP address of the Channels DVR server.
        port_number (int): The port number on which the API is running.

    Returns:
        list: A list of dictionaries containing movie data in JSON format,
        where each dictionary represents a single movie. Each dictionary
        should have the keys 'title', 'release_year', 'source', 'channel', 
        'verified, and 'path'.
    """
    api_url = 'http://' + server_ip_address + ':' + str(port_number) + \
              '/api/v1/movies'

    return requests.get(api_url).json()


##############################################################################
#                                                                            #
#                               Main execution                               #
#                                                                            #
##############################################################################

if __name__ == "__main__":
    # Create an ArgumentParser object
    parser = argparse.ArgumentParser(
                description = "Channels DVR movie list -> CSV file.",
                epilog = "If no options are specified, use the default URL: 127.0.0.1:8089")

    # Add the input arguments
    parser.add_argument('-i', '--ip_address', type=str, help='IP address of the Channels DVR server')
    parser.add_argument('-p', '--port_number', type=int, help='Port number of the Channels DVR server')
    parser.add_argument('-v', '--version', action='store_true', help='Print the version number')

    # Parse the arguments
    args = parser.parse_args()

    # Access the values of the arguments
    ip_address = args.ip_address
    port_number = args.port_number
    version = args.version

    # If the version flag is set, print the version number and exit
    if version:
        print(VERSION)
        sys.exit()

    # Check whether the user has given the IP address of the server.
    # If not, use the default loopback address.
    server_ip_address = ip_address
    if not ip_address:
        server_ip_address = LOOPBACK_ADDRESS
        
    # Check whether the user has given the port number of the server.
    # If not, use the default one.
    server_port_number = str(port_number)
    if not port_number:
        server_port_number = str(DEFAULT_PORT_NUMBER)
        
    print('Using Channels DVR server at: http://' + server_ip_address + ':' + server_port_number)
    print('')

    # Now, the magic happens...

    print('Getting the list of movies from Channels DVR...')
    json_movies = get_movies_from_channels_dvr_api(server_ip_address, server_port_number)
    print('Got ' + str(len(json_movies)) + ' movies.')
    print('')

    print('Writing the list of movies to the CSV file...')
    write_movie_list_to_csv_file(json_movies)
    print('')