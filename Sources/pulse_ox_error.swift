/**
 * \file    pulse_ox_error.swift
 * \author  Mauricio Villarroel
 * \date    Created: Feb 17, 2022
 * ____________________________________________________________________________
 *
 * Copyright (C) 2022 Mauricio Villarroel. All rights reserved.
 *
 * SPDX-License-Identifer:  GPL-2.0-only
 * ____________________________________________________________________________
 */

import Foundation


public enum Pulse_ox_error : Error, Equatable
{
    
    case empty_configuration
    
    case services_not_supported(_ services : String)
    
    case characteristics_not_supported(_ characteristics : String)
    
    case no_characteristics_configured(_ services: String)
    
}
