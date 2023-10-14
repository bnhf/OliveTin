"""
Author: Gildas Lefur (a.k.a. "mjitkop" in the Channels DVR forums)

Description: This script retrieves the list of channels from a Channels DVR server 
and writes it to a CSV file in such a way that you can see in which sources each channel
is provided.

Disclaimer: this is an unofficial script that is NOT supported by the
developers of Channels DVR.

For bug reports and support, go to: 
https://community.getchannels.com/t/python-script-channel-list-csv-file-to-easily-see-where-channels-are-available/36399?u=mjitkop

Version History:
- 2023.05.18.1458: Initial version of the script.
- 2023.05.19.1755: Fixed: channel names were not matching if they had different casings
- 2023.05.20.1328: Fixed: crash when a channel number contained a decimal point
"""

import argparse
import csv
import requests
import sys
from datetime import datetime

CSV_FILE_NAME_EXT    = '.csv'
CSV_FILE_NAME_BASE   = 'channels_dvr_channel_list_'
DEFAULT_PORT_NUMBER  = 8089
LOOPBACK_ADDRESS     = '127.0.0.1'
VERSION              = '2023.05.20.1328'
                       

##############################################################################
#                                                                            #
#                             Class definitions                              #
#                                                                            #
##############################################################################

class Source:
    '''Attributes and methods to handle one channel source.'''
    def __init__(self, source):
        '''
        Initialize the attributes of the current source.
        
        Input: source = one source in json format
           
        The json source looks like this:
           
        {"Provider":"m3u", "DeviceID":"M3U-PBS", "FriendlyName":"PBS", "ModelNumber":"HDHRCOMPAT-1", "Lineup":"X-M3U",
         "Channels":[{"ID":"WEDH", "GuideNumber":"1000", "GuideName":"WEDH", "HD":1, "Station":"53126"},
                     {"ID":"WNET", "GuideNumber":"1001", "GuideName":"WNET", "HD":1, "Station":"26182"}, 
                     {"ID":"WLIW", "GuideNumber":"1002", "GuideName":"WLIW", "HD":1, "Station":"34325"}]}
        '''
           
        self.source = source
        self.name = self.source['FriendlyName']
        self.channels  = self._get_channels()

    def _get_channels(self):
        '''
        Extract the channels from the current source.
        
        Return value: json dictionary that looks like this:
           
        {"1000":"WEDH", "1001":"WNET", "1002":"WLIW"}
        '''
        channels = {}

        for channel in self.source['Channels']:
            number = channel['GuideNumber']
            name   = channel['GuideName']
            channels[number] = name

        return channels
        
    
##############################################################################
#                                                                            #
#                            Function definitions                            #
#                                                                            #
##############################################################################

def write_channel_list_to_csv_file(sources):
    '''
    Given a list of instances of the Source class, process the information from 
    each source and create the CSV rows that get written to the file.

    Args:
        sources (list): A list of instances of the Source class.

    Returns:
        None: This function does not return anything, but it writes the data to a CSV file
        and prints a message indicating where the file can be found.

    Raises:
        None: This function does not raise any exceptions, but it assumes that the
        create_csv_file_name and create_csv_rows functions are defined and working properly.
    '''
    csv_file_name = create_csv_file_name()
    csv_rows_to_write = create_csv_rows(sources)
    
    with open(csv_file_name, 'w', newline='') as csv_file:
        csv_writer = csv.writer(csv_file)
        csv_writer.writerows(csv_rows_to_write)
    
    print("Channel information available in " + csv_file_name)

def create_csv_file_name():
    '''
    Generate a filename for a new CSV file based on the current date and time.

    Returns:
        str: A string containing the filename.
    '''
    time_stamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    csv_file_name = CSV_FILE_NAME_BASE + time_stamp + CSV_FILE_NAME_EXT
    
    return csv_file_name
    
def create_csv_rows(sources):
    '''
    Given a list of dictionaries containing movie data in JSON format, 
    create a list of rows for writing to a CSV file.

    Args:
        sources (list): A list of instances of the Source class.

    Returns:
        csv_rows (list): A list of sublists, where each sublist contains the channel
                         name, the number of sources that provide this channel, and
                         a series of channel numbers under the sources that provide 
                         the channel, or "-" if not provided by a source.
              
              Example:
              header = ['Channel name', 'Number of sources', 'Pluto TV', 'PBS']
              sublist = ['WNET', 1, -, '13'] 
                        (channel WNET is provided by 1 source: not by Pluto TV but #13 in PBS)
                        
              There are as many sublists as there are channels.
              
              In the end, csv_rows = [header, sublist #1, sublist #2, ... sublist #n]
    '''
    csv_rows = []
    
    source_names = get_source_names(sources)
    
    header = create_csv_header(source_names)
    
    csv_rows.append(header)
    
    channel_info = get_channel_info(sources)
    
    for channel_name, source_info in channel_info.items():
        row = [channel_name, len(source_info)]
        
        # Define the value for the "Free channels" column
        free_number = get_free_channel_number(source_info)
        row.append(free_number)
        
        for source_name in source_names:
            channel_number = source_info.get(source_name, '-')
            if is_channel_in_free_channel_range(channel_number):
                # Free channel already added to the "Free channels" column.
                # Don't report it again here.
                channel_number = '-'
            row.append(channel_number)
                
        csv_rows.append(row)
        
    return csv_rows
        
def get_source_names(sources):
    '''
    Extract all the names of the sources from the provided sources.

    Args:
        sources (list): A list of instances of the Source class.

    Returns:
        A list of strings representing the names of all the sources.

    Raises:
        None: This function does not raise any exceptions unless some unexpected error occurs.
    '''
    return [source.name for source in sources]

def create_csv_header(source_names):
    '''
    Generate the header that will be written first to the CSV file.
    The header contains "Channel name", "Number of sources", "Free Channels", and the names of 
    all available sources.
    
    Example:
        header = ['Channel name', 'Number of sources', 'Free channels', 'DirecTV', 'Pluto TV', 'Frndly TV']

    Args:
        source_names (list): list of all source names.

    Returns:
        header: a list of strings representing the top row of the CSV file.

    Raises:
        None: This function does not raise any exceptions unless some unexpected error occurs.
    '''
    header = ['Channel name', 'Number of sources', 'Free channels']
    for name in source_names:
        header.append(name)
        
    return header
    
def get_channel_info(sources):
    '''
    Generate a json dictionary that shows which sources provide each channel.
    
    Example:
        channel_info = {'MTV':{'DirecTV':'331'}, 'Hallmark':{'DirecTV':'6090', 'Frndly TV':'7010'}} 

    Args:
        sources (list): A list of instances of the Source class.

    Returns:
        channel_info: a json dictionary.

    Raises:
        None: This function does not raise any exceptions unless some unexpected error occurs.
    '''
    channel_info = {}
    for source in sources:
        for channel_number, channel_name in source.channels.items():
            
            channel_name = channel_name.upper()
            
            source_info = channel_info.get(channel_name, None)
            
            if not source_info:
                source_info = {}
            
            source_info[source.name] = channel_number
            
            channel_info[channel_name] = source_info
            
    return channel_info

def get_free_channel_number(source_info):
    '''
    Parse the content of source_info to see if it contains any channel numbers in 
    the 6700-6999 range. If this is the case, return that channel number as a string.
    If no channel numbers are found to be in this range, return '-'.
    This will be used to populate the "Free channels" column of the CSV file.

    Args:
        source_info (dict): json dictionary with keys = source names, and values = channel numbers
                            example: {'DirecTV':'6090', 'Frndly TV':'7012'}

    Returns:
        string: either a channel number as a string or the value '-'

    Raises:
        None: This function does not raise any exceptions unless some unexpected error occurs.
    '''
    free_channel_number = '-'
    for _, channel_number in source_info.items():
        try:
            number = int(channel_number)
            
            if number in range(6700, 7000):
                free_channel_number = channel_number
        except:
            # The channel number cannot be converted to an integer.
            # Most likely because it is an OTA channel number with a decimal point (i.e. 4.1)
            # Nothing to do in this case. This is definitely not in the range 6700-6999.
            pass
            
    return free_channel_number
    
def is_channel_in_free_channel_range(channel_number):
    '''
    Return True if the given channel number is in the range 6700-6999.
    Otherwise, return False.
   
    Args:
        channel_number (str): string value of a channel number

    Returns:
        boolean

    Raises:
        None: This function does not raise any exceptions unless some unexpected error occurs.
    '''
    is_free_channel = False
    
    try:
        number = int(channel_number)
        
        is_free_channel = number in range(6700, 7000)
    except:
        # The channel number cannot be converted to an integer.
        # Most likely because it is an OTA channel number with a decimal point (i.e. 4.1)
        # Nothing to do in this case. This is definitely not in the range 6700-6999.
        pass
    
    return is_free_channel

def get_source_info_from_channels_dvr_api(server_ip_address, port_number):
    '''
    Retrieve the details of all channel sources from a Channels DVR server.

    Args:
        server_ip_address (str): The IP address of the Channels DVR server.
        port_number (int): The port number on which the API is running.

    Returns:
        list: A list of instances of the Source class.
    '''
    api_url = 'http://' + server_ip_address + ':' + str(port_number) + '/devices'
    
    devices = requests.get(api_url).json()

    return [Source(source) for source in devices]


##############################################################################
#                                                                            #
#                               Main execution                               #
#                                                                            #
##############################################################################

if __name__ == "__main__":
    # Create an ArgumentParser object
    parser = argparse.ArgumentParser(
                description = "Channels DVR channel list -> CSV file.",
                epilog = "If no options are specified, the default URL will be used: http://127.0.0.1:8089")

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

    print('Getting the details of all the sources from Channels DVR...')
    sources = get_source_info_from_channels_dvr_api(server_ip_address, server_port_number)
    print('Got ' + str(len(sources)) + ' sources.')
    print('')

    print('Writing the channel information to the CSV file...')
    write_channel_list_to_csv_file(sources)
    print('')